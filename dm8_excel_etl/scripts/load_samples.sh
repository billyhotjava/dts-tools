#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SAMPLES_DIR="${DM8_SAMPLES_DIR:-}"
TARGET_DIR="${ROOT}/data/inbox"

usage() {
  cat <<'USAGE'
Usage: scripts/load_samples.sh [--from DIR] [--to DIR]

Copies sample ERP files into the inbox directory.

Default search order for samples:
  1) $DM8_SAMPLES_DIR (or --from)
  2) /samples (recommended Docker mount)
  3) ../docs/erp/samples (when running from repo root)
  4) ./docs/erp/samples (when repo root is mounted as /app)

Examples:
  # Local repo (dm8_excel_etl/):
  ./scripts/load_samples.sh

  # Docker: mount host samples dir to /samples, then inside container:
  ./scripts/load_samples.sh
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      SAMPLES_DIR="$2"
      shift 2
      ;;
    --to)
      TARGET_DIR="$2"
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

if [[ -z "${SAMPLES_DIR}" ]]; then
  if [[ -d "/samples" ]]; then
    SAMPLES_DIR="/samples"
  elif [[ -d "${ROOT}/../docs/erp/samples" ]]; then
    SAMPLES_DIR="${ROOT}/../docs/erp/samples"
  elif [[ -d "${ROOT}/docs/erp/samples" ]]; then
    SAMPLES_DIR="${ROOT}/docs/erp/samples"
  fi
fi

if [[ -z "${SAMPLES_DIR}" || ! -d "${SAMPLES_DIR}" ]]; then
  echo "Sample directory not found." >&2
  echo "Set DM8_SAMPLES_DIR, or mount samples to /samples (Docker), or ensure ../docs/erp/samples exists." >&2
  exit 2
fi

mkdir -p "${TARGET_DIR}"

shopt -s nullglob
FILES=("${SAMPLES_DIR}"/sample_*)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No files matched ${SAMPLES_DIR}/sample_*" >&2
  exit 2
fi

cp -av "${FILES[@]}" "${TARGET_DIR}/"
echo "[dm8-etl] samples loaded: from=${SAMPLES_DIR} to=${TARGET_DIR}"

