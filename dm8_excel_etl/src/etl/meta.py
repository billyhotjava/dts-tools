from __future__ import annotations

import datetime as dt
import logging
from pathlib import Path

from .db import Db, execute


def try_insert_batch_log(
    db: Db,
    *,
    batch_id: str,
    job_name: str,
    table_name: str,
    source_file: str | Path,
    total_rows: int | None,
    ok_rows: int | None,
    bad_rows: int | None,
    started_at: dt.datetime,
    finished_at: dt.datetime,
    status: str,
    message: str | None,
    logger: logging.Logger,
) -> None:
    sql = """
INSERT INTO etl_batch_log (
  batch_id, job_name, table_name, source_file,
  total_rows, ok_rows, bad_rows,
  started_at, finished_at,
  status, message
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""".strip()
    params = [
        batch_id,
        job_name,
        table_name,
        str(source_file),
        total_rows,
        ok_rows,
        bad_rows,
        started_at,
        finished_at,
        status,
        (message or "")[:2000],
    ]
    try:
        execute(db, sql, params)
    except Exception as e:
        logger.warning("skip etl_batch_log insert: %s", e)

