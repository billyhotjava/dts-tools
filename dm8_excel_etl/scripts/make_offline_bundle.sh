#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OUT_DIR="${ROOT}/dist_bundle"
FORCE="0"
SKIP_BUILD_WHEEL="0"
PYTHON_BIN="${PYTHON:-python3}"

usage() {
  cat <<'USAGE'
Usage: scripts/make_offline_bundle.sh [--output DIR] [--force] [--skip-build-wheel] [--python PYTHON]

Creates an offline delivery bundle containing:
  - source code, config, sql, scripts
  - wheels/ (copied from current project)
  - install_offline.sh (creates venv and installs from wheels)

Before running:
  - prepare wheels/ (incl. dependencies + project wheel).
  - for Kunpeng aarch64, build pyodbc wheel on aarch64 if needed.
  - recommend using the same Python major/minor as the target machine.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUT_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    --skip-build-wheel)
      SKIP_BUILD_WHEEL="1"
      shift
      ;;
    --python)
      PYTHON_BIN="$2"
      shift 2
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

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "Python not found: ${PYTHON_BIN}" >&2
  exit 2
fi

VERSION="$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("pyproject.toml").read_text(encoding="utf-8")
m = re.search(r'(?m)^version\\s*=\\s*\"([^\"]+)\"\\s*$', text)
print(m.group(1) if m else "0.0.0")
PY
)"
DATE="$(date +%Y%m%d)"
BUNDLE_NAME="dm8_excel_etl_${VERSION}_${DATE}"
BUNDLE_DIR="${OUT_DIR}/${BUNDLE_NAME}"

mkdir -p "${OUT_DIR}"
if [[ -e "${BUNDLE_DIR}" ]]; then
  if [[ "${FORCE}" == "1" ]]; then
    rm -rf "${BUNDLE_DIR}"
  else
    echo "Bundle already exists: ${BUNDLE_DIR} (use --force to overwrite)" >&2
    exit 2
  fi
fi

cd "${ROOT}"

if [[ "${SKIP_BUILD_WHEEL}" == "0" ]]; then
  mkdir -p wheels
  # Ensure pip exists and is new enough to build from pyproject.toml
  "${PYTHON_BIN}" -m ensurepip --upgrade >/dev/null 2>&1 || true
  "${PYTHON_BIN}" -m pip install -U pip setuptools wheel >/dev/null 2>&1 || true
  "${PYTHON_BIN}" -m pip wheel . -w wheels --no-deps --no-build-isolation >/dev/null
fi

mkdir -p "${BUNDLE_DIR}"

cp -a README.md pyproject.toml requirements.txt requirements-jdbc.txt "${BUNDLE_DIR}/" 2>/dev/null || true
cp -a .env.example "${BUNDLE_DIR}/" 2>/dev/null || true
cp -a config sql scripts src drivers "${BUNDLE_DIR}/"
cp -a lib "${BUNDLE_DIR}/" 2>/dev/null || true

mkdir -p "${BUNDLE_DIR}/data/inbox" "${BUNDLE_DIR}/data/archive" "${BUNDLE_DIR}/data/badrows" "${BUNDLE_DIR}/logs"

if [[ -d wheels ]]; then
  cp -a wheels "${BUNDLE_DIR}/"
else
  echo "WARN: wheels/ not found; offline install will fail without it." >&2
fi

cat >"${BUNDLE_DIR}/install_offline.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip >/dev/null 2>&1 || true

if [[ -d wheels ]]; then
  pip install --no-index --find-links=./wheels -r requirements.txt
  if [[ "${INSTALL_JDBC:-0}" == "1" && -f requirements-jdbc.txt ]]; then
    pip install --no-index --find-links=./wheels -r requirements-jdbc.txt
  fi

  WHEEL_FILE="$(ls -1 wheels/dm8_excel_etl-*.whl 2>/dev/null | head -n 1 || true)"
  if [[ -z "${WHEEL_FILE}" ]]; then
    echo "Project wheel not found in wheels/ (expected dm8_excel_etl-*.whl)." >&2
    echo "Build it on a build machine: python -m pip wheel . -w wheels --no-deps --no-build-isolation" >&2
    exit 2
  fi
  pip install --no-index --find-links=./wheels "${WHEEL_FILE}"
else
  echo "wheels/ not found; cannot do offline install." >&2
  exit 2
fi

echo "OK. Activate and run:"
echo "  source .venv/bin/activate"
echo "  dm8-etl --help"
EOS

chmod +x "${BUNDLE_DIR}/install_offline.sh"

cat >"${BUNDLE_DIR}/run_pipeline.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

source .venv/bin/activate
./scripts/one_click_test.sh --config "${1:-config/app.yaml}"
EOS
chmod +x "${BUNDLE_DIR}/run_pipeline.sh"

echo "Bundle created: ${BUNDLE_DIR}"
