from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from .config import OdbcConfig


class DbError(RuntimeError):
    pass


@dataclass(frozen=True)
class Db:
    conn: Any
    mode: str
    autocommit: bool

    def cursor(self) -> Any:
        return self.conn.cursor()

    def commit(self) -> None:
        if not self.autocommit:
            self.conn.commit()

    def rollback(self) -> None:
        if not self.autocommit:
            self.conn.rollback()

    def close(self) -> None:
        self.conn.close()


def _as_jdbc_param(value: Any) -> Any:
    import datetime as dt

    if isinstance(value, dt.datetime):
        s = value.strftime("%Y-%m-%d %H:%M:%S")
        if value.microsecond:
            s = f"{s}.{value.microsecond:06d}"
        try:
            import jpype  # type: ignore[import-not-found]

            if not jpype.isJVMStarted():
                return s
            Timestamp = jpype.JClass("java.sql.Timestamp")
            return Timestamp.valueOf(s)
        except Exception:
            return s

    if isinstance(value, dt.date):
        s = value.isoformat()
        try:
            import jpype  # type: ignore[import-not-found]

            if not jpype.isJVMStarted():
                return s
            Date = jpype.JClass("java.sql.Date")
            return Date.valueOf(s)
        except Exception:
            return s

    return value


def adapt_params(db: Db, params: Iterable[Any]) -> list[Any]:
    values = list(params)
    if db.mode != "jdbc":
        return values
    return [_as_jdbc_param(v) for v in values]


def adapt_param_rows(db: Db, rows: list[tuple[Any, ...]]) -> list[tuple[Any, ...]]:
    if db.mode != "jdbc":
        return rows
    return [tuple(_as_jdbc_param(v) for v in row) for row in rows]


def connect(odbc: OdbcConfig) -> Db:
    if odbc.mode == "auto":
        try:
            # Prefer ODBC first (it is the most common DM8 deployment mode).
            return connect(OdbcConfig(**{**odbc.__dict__, "mode": "odbc"}))  # type: ignore[arg-type]
        except Exception as odbc_exc:
            # Best-effort fallback to JDBC when configured.
            if odbc.jdbc_url and odbc.jdbc_driver and odbc.jdbc_jars:
                try:
                    return connect(OdbcConfig(**{**odbc.__dict__, "mode": "jdbc"}))  # type: ignore[arg-type]
                except Exception as jdbc_exc:
                    raise DbError(f"Auto connect failed. ODBC error: {odbc_exc}; JDBC error: {jdbc_exc}") from jdbc_exc
            raise DbError(f"Auto connect failed (no JDBC config to fallback). ODBC error: {odbc_exc}") from odbc_exc

    if odbc.mode == "jdbc":
        if not odbc.uid or not odbc.pwd:
            raise DbError("JDBC mode requires non-empty username/password (set `db.uid`/`db.pwd` or env DM8_UID/DM8_PWD)")

        try:
            import jaydebeapi  # type: ignore[import-not-found]
        except Exception as e:
            raise DbError("JDBC mode requires `jaydebeapi` (and typically JPype1) installed") from e

        if not odbc.jdbc_url or not odbc.jdbc_driver or not odbc.jdbc_jars:
            raise DbError("JDBC mode requires `db.jdbc_url`, `db.jdbc_driver`, `db.jdbc_jars`")

        jars = [str(Path(p).expanduser().resolve()) for p in odbc.jdbc_jars]
        missing = [p for p in jars if not Path(p).exists()]
        if missing:
            raise DbError(f"JDBC jar not found: {missing}")

        user = odbc.uid
        pwd = odbc.pwd
        try:
            conn = jaydebeapi.connect(odbc.jdbc_driver, odbc.jdbc_url, [user, pwd], jars)
            # best-effort set autocommit on underlying java connection
            try:
                conn.jconn.setAutoCommit(bool(odbc.autocommit))
            except Exception:
                pass
        except Exception as e:
            raise DbError(f"JDBC connection failed: {e}") from e

        return Db(conn=conn, mode="jdbc", autocommit=bool(odbc.autocommit))

    if odbc.connection_string:
        conn_str = odbc.connection_string
    elif odbc.dsn:
        parts = [f"DSN={odbc.dsn}"]
        if odbc.uid:
            parts.append(f"UID={odbc.uid}")
        if odbc.pwd:
            parts.append(f"PWD={odbc.pwd}")
        conn_str = ";".join(parts)
    else:
        raise DbError("ODBC config must provide `db.dsn` or `db.connection_string`")

    try:
        import pyodbc  # type: ignore[import-not-found]
        conn = pyodbc.connect(conn_str, autocommit=odbc.autocommit)
    except Exception as e:
        raise DbError(f"ODBC connection failed: {e}") from e

    return Db(conn=conn, mode="odbc", autocommit=bool(odbc.autocommit))


def execute(db: Db, sql: str, params: Iterable[Any] | None = None) -> None:
    try:
        cur = db.cursor()
        cur.execute(sql, adapt_params(db, params or []))
        cur.close()
        db.commit()
    except Exception as e:
        try:
            db.rollback()
        except Exception:
            pass
        raise DbError(f"SQL execute failed: {e}; sql={sql!r}") from e
