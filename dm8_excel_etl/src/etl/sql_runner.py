from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from .db import Db, DbError, execute


@dataclass(frozen=True)
class SqlRunResult:
    path: Path
    statements: int


def _split_sql(text: str) -> list[str]:
    stmts: list[str] = []
    buf: list[str] = []

    in_sq = False  # '
    in_dq = False  # "
    in_line_comment = False  # --
    in_block_comment = False  # /* */

    i = 0
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
                buf.append(ch)
            i += 1
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
                continue
            i += 1
            continue

        if not in_sq and not in_dq:
            if ch == "-" and nxt == "-":
                in_line_comment = True
                i += 2
                continue
            if ch == "/" and nxt == "*":
                in_block_comment = True
                i += 2
                continue

        if ch == "'" and not in_dq:
            # handle escaped '' inside string
            if in_sq and nxt == "'":
                buf.append("''")
                i += 2
                continue
            in_sq = not in_sq
            buf.append(ch)
            i += 1
            continue

        if ch == '"' and not in_sq:
            in_dq = not in_dq
            buf.append(ch)
            i += 1
            continue

        if ch == ";" and not in_sq and not in_dq:
            stmt = "".join(buf).strip()
            if stmt:
                stmts.append(stmt)
            buf.clear()
            i += 1
            continue

        buf.append(ch)
        i += 1

    tail = "".join(buf).strip()
    if tail:
        stmts.append(tail)
    return stmts


def run_sql_text(db: Db, sql_text: str) -> int:
    count = 0
    for stmt in _split_sql(sql_text):
        execute(db, stmt)
        count += 1
    return count


def run_sql_file(db: Db, path: str | Path) -> SqlRunResult:
    p = Path(path)
    if not p.exists() or not p.is_file():
        raise DbError(f"SQL file not found: {p}")
    text = p.read_text(encoding="utf-8")
    statements = run_sql_text(db, text)
    return SqlRunResult(path=p, statements=statements)


def iter_sql_files(directory: str | Path, pattern: str = "*.sql") -> Iterable[Path]:
    d = Path(directory)
    if not d.exists() or not d.is_dir():
        raise DbError(f"SQL directory not found: {d}")
    yield from sorted(d.glob(pattern))

