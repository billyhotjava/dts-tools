from __future__ import annotations

import csv
import datetime as dt
import logging
import re
import shutil
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Any, TextIO

from .config import AppConfig, JobConfig
from .db import Db, DbError, connect, execute
from .excel import ExcelError, ParsedRow, iter_rows
from .meta import try_insert_batch_log


_IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _safe_ident(name: str) -> str:
    # DM8 (and most SQL dialects) fold unquoted identifiers; quoting makes them case-sensitive.
    # Keep simple identifiers unquoted even if they are lowercase, so `ods_xxx` works.
    if _IDENT_RE.match(name):
        return name
    return '"' + name.replace('"', '""') + '"'


def _ensure_dirs(*paths: Path) -> None:
    for p in paths:
        p.mkdir(parents=True, exist_ok=True)


@dataclass(frozen=True)
class LoadResult:
    file: Path
    job: str
    table: str
    batch_id: str
    total_rows: int
    ok_rows: int
    bad_rows: int
    badrows_csv: Path | None
    archived_file: Path | None


def _badrows_writer(
    badrows_dir: Path,
    excel_file: Path,
    job: JobConfig,
    batch_id: str,
    column_order: list[str],
) -> tuple[Path, TextIO, csv.DictWriter]:
    ts = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    out = badrows_dir / f"{excel_file.stem}.{job.name}.{batch_id}.badrows.{ts}.csv"
    f = out.open("w", newline="", encoding="utf-8-sig")
    writer = csv.DictWriter(f, fieldnames=["__row__", "__error__"] + column_order)
    writer.writeheader()
    return out, f, writer


def _truncate_table(db: Db, table: str) -> None:
    try:
        execute(db, f"TRUNCATE TABLE {_safe_ident(table)}")
    except DbError:
        execute(db, f"DELETE FROM {_safe_ident(table)}")


def load_job_file(
    db: Db | None,
    config: AppConfig,
    job: JobConfig,
    excel_file: Path,
    batch_id: str,
    batch_size: int = 1000,
    dry_run: bool = False,
    logger: logging.Logger | None = None,
) -> LoadResult:
    logger = logger or logging.getLogger(__name__)
    _ensure_dirs(config.paths.badrows, config.paths.archive, config.paths.logs)

    if not dry_run and db is None:
        raise ValueError("db is required unless dry_run=True")

    column_order = [c.db for c in job.columns]
    _, rows_iter = iter_rows(str(excel_file), job.excel, job.columns)
    badrows_csv: Path | None = None
    badrows_file = None
    badrows_dict_writer: csv.DictWriter | None = None

    if job.mode == "truncate" and not dry_run:
        logger.info("truncate table=%s", job.table)
        _truncate_table(db, job.table)

    cols_sql = ", ".join(_safe_ident(c) for c in column_order)
    placeholders = ", ".join(["?"] * len(column_order))
    insert_sql = f"INSERT INTO {_safe_ident(job.table)} ({cols_sql}) VALUES ({placeholders})"

    total = 0
    ok = 0
    bad = 0
    batch: list[tuple[Any, ...]] = []

    cur: Any | None = None
    if not dry_run:
        cur = db.cursor()  # type: ignore[union-attr]
        try:
            cur.fast_executemany = True
        except Exception:
            pass

    try:
        for r in rows_iter:
            # skip fully empty mapped rows
            if all(v is None for v in r.values.values()):
                continue

            total += 1
            if r.ok:
                ok += 1
                if not dry_run:
                    vals: list[Any] = []
                    for c in column_order:
                        v = r.values[c]
                        if isinstance(v, Decimal):
                            v = str(v)  # keeps precision; DM will cast to NUMBER
                        vals.append(v)
                    batch.append(tuple(vals))
                    if len(batch) >= batch_size:
                        cur.executemany(insert_sql, batch)
                        batch.clear()
            else:
                bad += 1
                if badrows_dict_writer is None:
                    badrows_csv, badrows_file, badrows_dict_writer = _badrows_writer(
                        config.paths.badrows, excel_file, job, batch_id, column_order
                    )
                record: dict[str, Any] = {
                    "__row__": r.row_number,
                    "__error__": "; ".join(r.errors),
                }
                for col in column_order:
                    record[col] = r.values.get(col)
                badrows_dict_writer.writerow(record)

        if not dry_run and batch:
            cur.executemany(insert_sql, batch)
            batch.clear()
        if not dry_run:
            db.commit()
    except Exception as e:
        if not dry_run:
            try:
                db.rollback()
            except Exception:
                pass
        raise DbError(f"Insert failed: {e}") from e
    finally:
        if cur is not None:
            cur.close()
        if badrows_file is not None:
            badrows_file.close()

    archived: Path | None = None
    if not dry_run:
        ts = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
        archived = config.paths.archive / f"{excel_file.stem}.{batch_id}.{ts}{excel_file.suffix}"
        shutil.move(str(excel_file), str(archived))
        logger.info("archived %s -> %s", excel_file, archived)

    return LoadResult(
        file=excel_file,
        job=job.name,
        table=job.table,
        batch_id=batch_id,
        total_rows=total,
        ok_rows=ok,
        bad_rows=bad,
        badrows_csv=badrows_csv,
        archived_file=archived,
    )


def load_ods(
    config: AppConfig,
    job_name: str | None = None,
    batch_size: int = 1000,
    dry_run: bool = False,
    batch_id: str = "batch",
    logger: logging.Logger | None = None,
) -> list[LoadResult]:
    logger = logger or logging.getLogger(__name__)
    _ensure_dirs(config.paths.inbox, config.paths.badrows, config.paths.archive, config.paths.logs)

    jobs = [j for j in config.jobs if j.enabled]
    if job_name:
        jobs = [j for j in jobs if j.name == job_name]
    if not jobs:
        raise ValueError("No enabled jobs matched")

    db: Db | None = None
    if not dry_run:
        db = connect(config.odbc)

    try:
        results: list[LoadResult] = []
        for job in jobs:
            files = sorted(Path(config.paths.inbox).glob(job.excel.pattern))
            if not files:
                logger.warning("no files matched inbox=%s pattern=%s", config.paths.inbox, job.excel.pattern)
                continue
            for f in files:
                logger.info("load job=%s file=%s table=%s dry_run=%s", job.name, f, job.table, dry_run)
                try:
                    started_at = dt.datetime.now()
                    results.append(
                        load_job_file(
                            db=db,
                            config=config,
                            job=job,
                            excel_file=f,
                            batch_id=batch_id,
                            batch_size=batch_size,
                            dry_run=dry_run,
                            logger=logger,
                        )
                    )
                    finished_at = dt.datetime.now()
                    if not dry_run and db is not None:
                        r = results[-1]
                        try_insert_batch_log(
                            db=db,
                            batch_id=batch_id,
                            job_name=job.name,
                            table_name=job.table,
                            source_file=f,
                            total_rows=r.total_rows,
                            ok_rows=r.ok_rows,
                            bad_rows=r.bad_rows,
                            started_at=started_at,
                            finished_at=finished_at,
                            status="SUCCESS",
                            message=None,
                            logger=logger,
                        )
                except (ExcelError, DbError) as e:
                    logger.exception("failed job=%s file=%s: %s", job.name, f, e)
                    finished_at = dt.datetime.now()
                    if not dry_run and db is not None:
                        try_insert_batch_log(
                            db=db,
                            batch_id=batch_id,
                            job_name=job.name,
                            table_name=job.table,
                            source_file=f,
                            total_rows=None,
                            ok_rows=None,
                            bad_rows=None,
                            started_at=started_at,
                            finished_at=finished_at,
                            status="FAILED",
                            message=str(e),
                            logger=logger,
                        )
                    raise
        return results
    finally:
        if db is not None:
            db.close()
