#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG="config/app.yaml"
SKIP_DDL="0"
DRY_RUN="0"
RUN_DDL_IN_DRY_RUN="0"
PY="python3"

usage() {
  cat <<'USAGE'
Usage: scripts/one_click_test.sh [--config PATH] [--skip-ddl] [--dry-run] [--run-ddl]

Runs the full offline pipeline:
  1) run-sql (sql/ddl)
  2) load-ods (Excel -> ODS)
  3) build-mdm (ODS -> MDM)
  4) build-ads (ODS/MDM -> ADS)

Notes:
  - Put Excel files in data/inbox/ (filenames must match config).
  - DB credentials can be injected via env: DM8_DSN / DM8_UID / DM8_PWD.
  - When --dry-run is set, DDL is skipped by default (no DB required).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG="$2"
      shift 2
      ;;
    --skip-ddl)
      SKIP_DDL="1"
      shift
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    --run-ddl)
      RUN_DDL_IN_DRY_RUN="1"
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

cd "$ROOT"

if [[ -x "${ROOT}/.venv/bin/python" ]]; then
  PY="${ROOT}/.venv/bin/python"
fi

if command -v dm8-etl >/dev/null 2>&1; then
  ETL=(dm8-etl)
else
  export PYTHONPATH="${ROOT}/src${PYTHONPATH:+:${PYTHONPATH}}"
  ETL=("${PY}" -m etl.cli)
fi

BATCH_ID="$(date +%Y%m%d%H%M%S)_$("${PY}" -c 'import uuid; print(uuid.uuid4().hex[:8])')"

echo "[dm8-etl] batch_id=${BATCH_ID}"
echo "[dm8-etl] config=${CONFIG}"

if [[ "${DRY_RUN}" == "1" && "${RUN_DDL_IN_DRY_RUN}" != "1" ]]; then
  echo "[dm8-etl] dry-run: skip ddl (use --run-ddl to force)"
elif [[ "${SKIP_DDL}" == "0" ]]; then
  "${ETL[@]}" run-sql --config "${CONFIG}" --dir "sql/ddl" --batch-id "${BATCH_ID}"
else
  echo "[dm8-etl] skip ddl"
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  "${ETL[@]}" load-ods --config "${CONFIG}" --dry-run --batch-id "${BATCH_ID}"
else
  "${ETL[@]}" load-ods --config "${CONFIG}" --batch-id "${BATCH_ID}"
fi

if [[ "${DRY_RUN}" == "0" ]]; then
  "${ETL[@]}" build-mdm --config "${CONFIG}" --batch-id "${BATCH_ID}"
  "${ETL[@]}" build-ads --config "${CONFIG}" --batch-id "${BATCH_ID}"
fi

echo "[dm8-etl] done; logs=logs/ (etl_${BATCH_ID}.log)"
