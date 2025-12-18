#!/usr/bin/env bash
set -euo pipefail

# Prepare offline wheels/ for the current platform + Python interpreter.
#
# Typical usage (on a connected build machine, same arch as offline target):
#   PYTHON=/opt/python3.10/bin/python3.10 INSTALL_JDBC=1 ./scripts/prepare_wheels.sh
#
# Notes:
# - pyodbc may require: gcc + unixODBC-devel (sql.h / odbc_config).
# - JPype1 may require: gcc + python headers (already present if you built Python) and a JDK for runtime (not for wheel build).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON:-python3}"
WHEELS_DIR="${ROOT}/wheels"
INSTALL_JDBC="${INSTALL_JDBC:-0}"

usage() {
  cat <<'USAGE'
Usage: scripts/prepare_wheels.sh [--python PYTHON] [--wheels DIR] [--with-jdbc]

Builds a complete offline wheels directory for this repo:
  - wheels for requirements.txt
  - optional wheels for requirements-jdbc.txt
  - project wheel (dm8_excel_etl-*.whl)

Examples:
  PYTHON=/opt/python3.10/bin/python3.10 ./scripts/prepare_wheels.sh
  PYTHON=/opt/python3.10/bin/python3.10 INSTALL_JDBC=1 ./scripts/prepare_wheels.sh
  ./scripts/prepare_wheels.sh --python /opt/python3.10/bin/python3.10 --with-jdbc
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --python)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --wheels)
      WHEELS_DIR="$2"
      shift 2
      ;;
    --with-jdbc)
      INSTALL_JDBC="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "${ROOT}"

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "Python not found: ${PYTHON_BIN}" >&2
  exit 2
fi

mkdir -p "${WHEELS_DIR}"

echo "[dm8-etl] python=${PYTHON_BIN}"
"${PYTHON_BIN}" -c 'import sys; print("[dm8-etl] python_version=" + sys.version.split()[0])'

# Ensure pip toolchain exists.
"${PYTHON_BIN}" -m ensurepip --upgrade >/dev/null 2>&1 || true
"${PYTHON_BIN}" -m pip install -U pip setuptools wheel >/dev/null

# Help users when pyodbc build deps are missing (common on fresh OS).
if rg -q -- "^pyodbc==" requirements.txt 2>/dev/null; then
  if ! command -v odbc_config >/dev/null 2>&1; then
    echo "[dm8-etl] WARN: odbc_config not found; pyodbc wheel build may fail (install unixODBC-devel)." >&2
  fi
  if [[ ! -f /usr/include/sql.h && ! -f /usr/local/include/sql.h ]]; then
    echo "[dm8-etl] WARN: sql.h not found; pyodbc wheel build may fail (install unixODBC-devel)." >&2
  fi
fi

echo "[dm8-etl] build wheels: requirements.txt -> ${WHEELS_DIR}"
"${PYTHON_BIN}" -m pip wheel -r requirements.txt -w "${WHEELS_DIR}"

if [[ "${INSTALL_JDBC}" == "1" && -f requirements-jdbc.txt ]]; then
  echo "[dm8-etl] build wheels: requirements-jdbc.txt -> ${WHEELS_DIR}"
  "${PYTHON_BIN}" -m pip wheel -r requirements-jdbc.txt -w "${WHEELS_DIR}"
fi

echo "[dm8-etl] build project wheel -> ${WHEELS_DIR}"
"${PYTHON_BIN}" -m pip wheel . -w "${WHEELS_DIR}" --no-deps --no-build-isolation

echo "[dm8-etl] done; wheels_count=$(ls -1 "${WHEELS_DIR}" | wc -l | tr -d ' ') dir=${WHEELS_DIR}"

