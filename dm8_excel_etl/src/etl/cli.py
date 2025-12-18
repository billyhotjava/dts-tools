from __future__ import annotations

import argparse
import datetime as dt
import logging
import sys
import uuid
from pathlib import Path

from . import __version__
from .config import ConfigError, load_config
from .db import DbError, connect
from .loader import load_ods
from .meta import try_insert_batch_log
from .sql_runner import iter_sql_files, run_sql_file


def _setup_logging(log_dir: Path, verbose: bool, batch_id: str) -> logging.Logger:
    log_dir.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("dm8_excel_etl")
    logger.handlers.clear()
    logger.setLevel(logging.DEBUG if verbose else logging.INFO)

    fmt = logging.Formatter("%(asctime)s %(levelname)s %(message)s")

    sh = logging.StreamHandler(stream=sys.stdout)
    sh.setLevel(logging.DEBUG if verbose else logging.INFO)
    sh.setFormatter(fmt)
    logger.addHandler(sh)

    fh = logging.FileHandler(log_dir / "etl.log", encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    fh2 = logging.FileHandler(log_dir / f"etl_{batch_id}.log", encoding="utf-8")
    fh2.setLevel(logging.DEBUG)
    fh2.setFormatter(fmt)
    logger.addHandler(fh2)

    return logger


def _cmd_load_ods(args: argparse.Namespace) -> int:
    try:
        cfg = load_config(args.config)
    except ConfigError as e:
        print(f"Config error: {e}", file=sys.stderr)
        return 2

    batch_id = args.batch_id or dt_batch_id()
    logger = _setup_logging(cfg.paths.logs, verbose=args.verbose, batch_id=batch_id)
    try:
        results = load_ods(
            config=cfg,
            job_name=args.job,
            batch_size=(args.batch_size or cfg.odbc.batch_size),
            dry_run=args.dry_run,
            batch_id=batch_id,
            logger=logger,
        )
    except Exception as e:
        logger.error("load-ods failed: %s", e)
        return 1

    for r in results:
        logger.info(
            "done file=%s job=%s table=%s total=%s ok=%s bad=%s badrows=%s",
            r.file,
            r.job,
            r.table,
            r.total_rows,
            r.ok_rows,
            r.bad_rows,
            r.badrows_csv,
        )
    return 0


def _cmd_run_sql(args: argparse.Namespace) -> int:
    try:
        cfg = load_config(args.config)
    except ConfigError as e:
        print(f"Config error: {e}", file=sys.stderr)
        return 2

    batch_id = args.batch_id or dt_batch_id()
    logger = _setup_logging(cfg.paths.logs, verbose=args.verbose, batch_id=batch_id)

    try:
        db = connect(cfg.odbc)
    except DbError as e:
        logger.error("db connect failed: %s", e)
        return 2

    try:
        def _resolve(p: Path) -> Path:
            return p if p.is_absolute() else (cfg.paths.root / p).resolve()

        files: list[Path] = []
        if args.path:
            files.extend([_resolve(Path(p)) for p in args.path])
        if args.dir:
            files.extend(list(iter_sql_files(_resolve(Path(args.dir)), pattern=args.pattern)))
        if not files:
            logger.error("no sql files specified (use --path or --dir)")
            return 2

        for p in files:
            try:
                started_at = dt.datetime.now()
                r = run_sql_file(db, p)
                finished_at = dt.datetime.now()
                logger.info("run-sql ok file=%s statements=%s", r.path, r.statements)
                try_insert_batch_log(
                    db,
                    batch_id=batch_id,
                    job_name=str(getattr(args, "cmd", "run-sql")),
                    table_name="(sql)",
                    source_file=r.path,
                    total_rows=r.statements,
                    ok_rows=r.statements,
                    bad_rows=0,
                    started_at=started_at,
                    finished_at=finished_at,
                    status="SUCCESS",
                    message=None,
                    logger=logger,
                )
            except Exception as e:
                finished_at = dt.datetime.now()
                logger.error("run-sql failed file=%s err=%s", p, e)
                try_insert_batch_log(
                    db,
                    batch_id=batch_id,
                    job_name=str(getattr(args, "cmd", "run-sql")),
                    table_name="(sql)",
                    source_file=p,
                    total_rows=None,
                    ok_rows=None,
                    bad_rows=None,
                    started_at=started_at,
                    finished_at=finished_at,
                    status="FAILED",
                    message=str(e),
                    logger=logger,
                )
                if not args.continue_on_error:
                    return 1
        return 0
    finally:
        db.close()


def _cmd_build_mdm(args: argparse.Namespace) -> int:
    args = argparse.Namespace(**vars(args))
    if not args.sql:
        args.path = [str(Path("sql/mdm/01_build_mdm.sql"))]
    else:
        args.path = [args.sql]
    args.dir = None
    args.pattern = "*.sql"
    return _cmd_run_sql(args)


def _cmd_build_ads(args: argparse.Namespace) -> int:
    args = argparse.Namespace(**vars(args))
    if not args.sql:
        args.path = [str(Path("sql/ads/01_refresh_ads.sql"))]
    else:
        args.path = [args.sql]
    args.dir = None
    args.pattern = "*.sql"
    return _cmd_run_sql(args)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="dm8-etl")
    p.add_argument("--version", action="version", version=__version__)

    sub = p.add_subparsers(dest="cmd", required=True)

    load_p = sub.add_parser("load-ods", help="Load Excel files into ODS tables")
    load_p.add_argument("--config", default="config/app.yaml", help="Path to app.yaml")
    load_p.add_argument("--job", default=None, help="Only run a single job by name")
    load_p.add_argument("--batch-size", type=int, default=None, help="executemany batch size (default from config)")
    load_p.add_argument("--batch-id", default=None, help="Optional batch id; default auto-generated")
    load_p.add_argument("--dry-run", action="store_true", help="Validate and parse only; do not write to DB")
    load_p.add_argument("-v", "--verbose", action="store_true", help="Verbose logs")
    load_p.set_defaults(func=_cmd_load_ods)

    run_p = sub.add_parser("run-sql", help="Run one or more .sql files")
    run_p.add_argument("--config", default="config/app.yaml", help="Path to app.yaml")
    run_p.add_argument("--path", action="append", default=None, help="SQL file path (repeatable)")
    run_p.add_argument("--dir", default=None, help="Directory of .sql files")
    run_p.add_argument("--pattern", default="*.sql", help="Glob pattern when using --dir")
    run_p.add_argument("--continue-on-error", action="store_true", help="Keep going when a file fails")
    run_p.add_argument("--batch-id", default=None, help="Optional batch id; default auto-generated")
    run_p.add_argument("-v", "--verbose", action="store_true", help="Verbose logs")
    run_p.set_defaults(func=_cmd_run_sql)

    mdm_p = sub.add_parser("build-mdm", help="Build MDM layer (runs sql/mdm/01_build_mdm.sql)")
    mdm_p.add_argument("--config", default="config/app.yaml", help="Path to app.yaml")
    mdm_p.add_argument("--sql", default=None, help="Override SQL file path")
    mdm_p.add_argument("--continue-on-error", action="store_true", help="Ignored (single file)")
    mdm_p.add_argument("--batch-id", default=None, help="Optional batch id; default auto-generated")
    mdm_p.add_argument("-v", "--verbose", action="store_true", help="Verbose logs")
    mdm_p.set_defaults(func=_cmd_build_mdm)

    ads_p = sub.add_parser("build-ads", help="Build ADS layer (runs sql/ads/01_refresh_ads.sql)")
    ads_p.add_argument("--config", default="config/app.yaml", help="Path to app.yaml")
    ads_p.add_argument("--sql", default=None, help="Override SQL file path")
    ads_p.add_argument("--continue-on-error", action="store_true", help="Ignored (single file)")
    ads_p.add_argument("--batch-id", default=None, help="Optional batch id; default auto-generated")
    ads_p.add_argument("-v", "--verbose", action="store_true", help="Verbose logs")
    ads_p.set_defaults(func=_cmd_build_ads)

    return p


def _todo(name: str) -> int:
    print(f"{name} not implemented yet (see dm8_guide.md TODO list).", file=sys.stderr)
    return 3


def dt_batch_id() -> str:
    return f"{uuid.uuid4().hex}"


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
