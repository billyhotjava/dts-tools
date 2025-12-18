from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

import os
import re
import yaml


class ConfigError(ValueError):
    pass


Mode = Literal["append", "truncate"]
ColumnType = Literal["str", "int", "float", "decimal", "date", "datetime", "bool"]
DbMode = Literal["odbc", "jdbc", "auto"]


@dataclass(frozen=True)
class OdbcConfig:
    dsn: str | None
    uid: str | None
    pwd: str | None
    mode: DbMode = "odbc"
    autocommit: bool = False
    batch_size: int = 1000
    connection_string: str | None = None
    jdbc_url: str | None = None
    jdbc_driver: str | None = None
    jdbc_jars: list[str] | None = None


@dataclass(frozen=True)
class PathsConfig:
    root: Path
    inbox: Path
    archive: Path
    badrows: Path
    logs: Path


@dataclass(frozen=True)
class ExcelConfig:
    pattern: str = "*.xlsx"
    sheet: str | None = None
    header_row: int = 1
    start_row: int = 2
    csv_encoding: str = "utf-8-sig"
    csv_delimiter: str = ","
    csv_quotechar: str = '"'


@dataclass(frozen=True)
class ColumnMapping:
    excel: str
    db: str
    type: ColumnType = "str"
    required: bool = False
    default: Any | None = None
    max_length: int | None = None


@dataclass(frozen=True)
class JobConfig:
    name: str
    enabled: bool
    table: str
    mode: Mode
    excel: ExcelConfig
    columns: list[ColumnMapping]


@dataclass(frozen=True)
class AppConfig:
    odbc: OdbcConfig
    paths: PathsConfig
    jobs: list[JobConfig]


def _require(mapping: dict[str, Any], key: str, ctx: str) -> Any:
    if key not in mapping:
        raise ConfigError(f"Missing required key `{ctx}.{key}`")
    return mapping[key]


def _as_bool(value: Any, default: bool = False) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    if isinstance(value, str):
        v = value.strip().lower()
        if v in {"true", "1", "yes", "y", "on"}:
            return True
        if v in {"false", "0", "no", "n", "off"}:
            return False
    raise ConfigError(f"Invalid boolean value: {value!r}")


_ENV_VAR_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)(?::-([^}]*))?\}")


def _expand_env_vars(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: _expand_env_vars(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_expand_env_vars(v) for v in value]
    if not isinstance(value, str) or "${" not in value:
        return value

    def _repl(match: re.Match[str]) -> str:
        var = match.group(1)
        default = match.group(2)
        if var in os.environ:
            return os.environ[var]
        if default is not None:
            return default
        raise ConfigError(f"Missing required environment variable: {var}")

    return _ENV_VAR_PATTERN.sub(_repl, value)


def _load_dotenv(dotenv_path: Path) -> None:
    if not dotenv_path.exists() or not dotenv_path.is_file():
        return

    for raw_line in dotenv_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        if "=" not in line:
            continue

        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()
        if not key or key.startswith("#"):
            continue

        if val.startswith(("'", '"')) and len(val) >= 2 and val.endswith(val[0]):
            val = val[1:-1]
        else:
            # support trailing comments: KEY=value  # comment
            val = re.split(r"\s+#", val, maxsplit=1)[0].strip()

        if key not in os.environ:
            os.environ[key] = val


def load_config(path: str | Path) -> AppConfig:
    config_path = Path(path)
    if not config_path.exists():
        raise ConfigError(f"Config file not found: {config_path}")

    # Load optional .env without introducing extra dependency (python-dotenv).
    # Precedence: real environment > .env.
    _load_dotenv(config_path.parent / ".env")
    _load_dotenv(config_path.parent.parent / ".env")

    raw = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ConfigError("Config root must be a mapping")
    raw = _expand_env_vars(raw)

    def _resolve_root(paths_raw: dict[str, Any] | None) -> Path:
        if paths_raw and "root" in paths_raw and paths_raw["root"] is not None:
            return (config_path.parent / str(paths_raw["root"])).resolve()
        candidate = config_path.parent
        if (candidate / "data").exists():
            return candidate.resolve()
        return config_path.parent.parent.resolve()

    def _parse_paths(root_raw: dict[str, Any] | None) -> PathsConfig:
        if root_raw is None:
            root = _resolve_root(None)
            return PathsConfig(
                root=root,
                inbox=(root / "data/inbox").resolve(),
                archive=(root / "data/archive").resolve(),
                badrows=(root / "data/badrows").resolve(),
                logs=(root / "logs").resolve(),
            )
        if not isinstance(root_raw, dict):
            raise ConfigError("`paths` must be a mapping")
        root = _resolve_root(root_raw)
        return PathsConfig(
            root=root,
            inbox=(root / str(_require(root_raw, "inbox", "paths"))).resolve(),
            archive=(root / str(_require(root_raw, "archive", "paths"))).resolve(),
            badrows=(root / str(_require(root_raw, "badrows", "paths"))).resolve(),
            logs=(root / str(_require(root_raw, "logs", "paths"))).resolve(),
        )

    def _parse_csv(csv_raw: Any | None, ctx: str) -> tuple[str, str, str]:
        if csv_raw is None:
            return ("utf-8-sig", ",", '"')
        if not isinstance(csv_raw, dict):
            raise ConfigError(f"`{ctx}` must be a mapping")
        encoding = str(csv_raw.get("encoding") or "utf-8-sig")
        delimiter = str(csv_raw.get("delimiter") or ",")
        quotechar = str(csv_raw.get("quotechar") or '"')
        if len(delimiter) != 1:
            raise ConfigError(f"`{ctx}.delimiter` must be a single character")
        if len(quotechar) != 1:
            raise ConfigError(f"`{ctx}.quotechar` must be a single character")
        return (encoding, delimiter, quotechar)

    def _none_if_blank(v: Any) -> str | None:
        if v is None:
            return None
        s = str(v).strip()
        return s if s else None

    def _parse_odbc(odbc_raw: dict[str, Any], ctx: str, base_dir: Path) -> OdbcConfig:
        if not isinstance(odbc_raw, dict):
            raise ConfigError(f"`{ctx}` must be a mapping")
        batch_size = int(odbc_raw.get("batch_size") or 1000)
        if batch_size <= 0:
            raise ConfigError(f"`{ctx}.batch_size` must be > 0")
        mode = str(odbc_raw.get("mode") or "odbc").lower()
        if mode not in {"odbc", "jdbc", "auto"}:
            raise ConfigError(f"`{ctx}.mode` must be one of: odbc, jdbc, auto")

        uid = _none_if_blank(odbc_raw.get("uid"))
        pwd = _none_if_blank(odbc_raw.get("pwd"))

        jdbc_jars: list[str] | None = None
        if "jdbc_jars" in odbc_raw and odbc_raw["jdbc_jars"] is not None:
            jars_raw = odbc_raw["jdbc_jars"]
            if isinstance(jars_raw, str):
                jdbc_jars = [jars_raw]
            elif isinstance(jars_raw, list) and all(isinstance(x, str) for x in jars_raw):
                jdbc_jars = list(jars_raw)
            else:
                raise ConfigError(f"`{ctx}.jdbc_jars` must be a string or list of strings")
            jdbc_jars = [str((base_dir / p).resolve()) if not Path(p).is_absolute() else str(Path(p).resolve()) for p in jdbc_jars]

        return OdbcConfig(
            mode=mode,  # type: ignore[assignment]
            dsn=_none_if_blank(odbc_raw.get("dsn")),
            uid=uid,
            pwd=pwd,
            autocommit=_as_bool(odbc_raw.get("autocommit"), default=False),
            batch_size=batch_size,
            connection_string=_none_if_blank(odbc_raw.get("connection_string")),
            jdbc_url=_none_if_blank(odbc_raw.get("jdbc_url")),
            jdbc_driver=_none_if_blank(odbc_raw.get("jdbc_driver")),
            jdbc_jars=jdbc_jars,
        )

    def _parse_columns(columns_raw: Any, ctx: str) -> list[ColumnMapping]:
        if not isinstance(columns_raw, list) or not columns_raw:
            raise ConfigError(f"`{ctx}` must be a non-empty list")
        columns: list[ColumnMapping] = []
        for cidx, c_raw in enumerate(columns_raw):
            cctx = f"{ctx}[{cidx}]"
            if not isinstance(c_raw, dict):
                raise ConfigError(f"`{cctx}` must be a mapping")

            ctype = c_raw.get("type") or "str"
            if ctype not in {"str", "int", "float", "decimal", "date", "datetime", "bool"}:
                raise ConfigError(f"Unsupported `{cctx}.type`: {ctype!r}")

            columns.append(
                ColumnMapping(
                    excel=str(_require(c_raw, "excel", cctx)),
                    db=str(_require(c_raw, "db", cctx)),
                    type=ctype,  # type: ignore[assignment]
                    required=_as_bool(c_raw.get("required"), default=False),
                    default=c_raw.get("default"),
                    max_length=(int(c_raw["max_length"]) if "max_length" in c_raw else None),
                )
            )
        return columns

    # ------------------------------------------------------------
    # Schema A (existing): odbc/paths/jobs
    # Schema B (new): db/excel/tables (closer to ERP export usage)
    # ------------------------------------------------------------
    if "jobs" in raw or "odbc" in raw:
        paths = _parse_paths(raw.get("paths"))
        odbc_raw = _require(raw, "odbc", "root")
        odbc = _parse_odbc(odbc_raw, "odbc", base_dir=paths.root)
        csv_defaults = _parse_csv(raw.get("csv"), "csv")

        jobs_raw = _require(raw, "jobs", "root")
        if not isinstance(jobs_raw, list):
            raise ConfigError("`jobs` must be a list")

        jobs: list[JobConfig] = []
        for idx, job_raw in enumerate(jobs_raw):
            ctx = f"jobs[{idx}]"
            if not isinstance(job_raw, dict):
                raise ConfigError(f"`{ctx}` must be a mapping")

            excel_raw = _require(job_raw, "excel", ctx)
            if not isinstance(excel_raw, dict):
                raise ConfigError(f"`{ctx}.excel` must be a mapping")

            csv_cfg = _parse_csv(excel_raw.get("csv"), f"{ctx}.excel.csv")
            if excel_raw.get("csv") is None:
                csv_cfg = csv_defaults

            excel = ExcelConfig(
                pattern=str(excel_raw.get("pattern") or "*.xlsx"),
                sheet=excel_raw.get("sheet"),
                header_row=int(excel_raw.get("header_row") or 1),
                start_row=int(excel_raw.get("start_row") or 2),
                csv_encoding=csv_cfg[0],
                csv_delimiter=csv_cfg[1],
                csv_quotechar=csv_cfg[2],
            )
            if excel.header_row < 1 or excel.start_row < 1:
                raise ConfigError(f"`{ctx}.excel.header_row/start_row` must be >= 1")
            if excel.start_row <= excel.header_row:
                raise ConfigError(f"`{ctx}.excel.start_row` must be > header_row")

            columns = _parse_columns(_require(job_raw, "columns", ctx), f"{ctx}.columns")

            mode = str(job_raw.get("mode") or "append")
            if mode not in {"append", "truncate"}:
                raise ConfigError(f"Unsupported `{ctx}.mode`: {mode!r}")

            jobs.append(
                JobConfig(
                    name=str(_require(job_raw, "name", ctx)),
                    enabled=_as_bool(job_raw.get("enabled"), default=True),
                    table=str(_require(job_raw, "table", ctx)),
                    mode=mode,  # type: ignore[assignment]
                    excel=excel,
                    columns=columns,
                )
            )

        if not jobs:
            raise ConfigError("No jobs configured")

        return AppConfig(odbc=odbc, paths=paths, jobs=jobs)

    if "tables" in raw or "db" in raw:
        db_raw = _require(raw, "db", "root")
        paths = _parse_paths(raw.get("paths"))
        odbc = _parse_odbc(db_raw, "db", base_dir=paths.root)
        csv_defaults = _parse_csv(raw.get("csv"), "csv")

        excel_raw = raw.get("excel") or {}
        if not isinstance(excel_raw, dict):
            raise ConfigError("`excel` must be a mapping")
        header_row = int(excel_raw.get("header_row") or 1)
        if header_row < 1:
            raise ConfigError("`excel.header_row` must be >= 1")

        tables_raw = _require(raw, "tables", "root")
        if not isinstance(tables_raw, dict) or not tables_raw:
            raise ConfigError("`tables` must be a non-empty mapping")

        jobs: list[JobConfig] = []
        for table_name, t_raw in tables_raw.items():
            ctx = f"tables.{table_name}"
            if not isinstance(t_raw, dict):
                raise ConfigError(f"`{ctx}` must be a mapping")
            file_pattern = str(_require(t_raw, "file", ctx))
            sheet = t_raw.get("sheet")
            mode = str(t_raw.get("mode") or "truncate")
            if mode not in {"append", "truncate"}:
                raise ConfigError(f"Unsupported `{ctx}.mode`: {mode!r}")

            # allow per-table override
            t_header_row = int(t_raw.get("header_row") or header_row)
            t_start_row = int(t_raw.get("start_row") or (t_header_row + 1))
            if t_start_row <= t_header_row:
                raise ConfigError(f"`{ctx}.start_row` must be > header_row")

            csv_cfg = _parse_csv(t_raw.get("csv"), f"{ctx}.csv")
            if t_raw.get("csv") is None:
                csv_cfg = csv_defaults

            excel = ExcelConfig(
                pattern=file_pattern,
                sheet=(str(sheet) if sheet is not None else None),
                header_row=t_header_row,
                start_row=t_start_row,
                csv_encoding=csv_cfg[0],
                csv_delimiter=csv_cfg[1],
                csv_quotechar=csv_cfg[2],
            )
            columns = _parse_columns(_require(t_raw, "columns", ctx), f"{ctx}.columns")

            jobs.append(
                JobConfig(
                    name=str(table_name),
                    enabled=_as_bool(t_raw.get("enabled"), default=True),
                    table=str(table_name),
                    mode=mode,  # type: ignore[assignment]
                    excel=excel,
                    columns=columns,
                )
            )

        return AppConfig(odbc=odbc, paths=paths, jobs=jobs)

    raise ConfigError("Unsupported config schema (expected `odbc/jobs` or `db/tables`)")
