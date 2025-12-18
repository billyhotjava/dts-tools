#!/usr/bin/env bash
set -euo pipefail

# DM8 ODBC 在部分 Linux 发行版上会尝试从相对路径加载加密/SSL 动态库：
#   ./lib/libssl.so
#   ./lib/libcrypto.so
# 若系统只安装了运行库（例如 OpenSSL 3 的 libssl.so.3/libcrypto.so.3）但没有 *-dev 提供的 libssl.so/libcrypto.so，
# 则会出现：
#   Encryption module failed to load (-70089)
#
# 本脚本会在项目根目录创建 lib/ 并尽量为 libssl.so / libcrypto.so 建立本地软链接，
# 从而让 ODBC 驱动能在不改系统的情况下运行（便于本机联调）。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="${ROOT}/lib"

mkdir -p "${LIB_DIR}"

pick_first_existing() {
  local candidates=("$@")
  local p
  for p in "${candidates[@]}"; do
    if [[ -f "${p}" ]]; then
      echo "${p}"
      return 0
    fi
  done
  return 1
}

link_if_missing() {
  local name="$1"   # e.g. libssl.so
  shift
  local target
  if [[ -f "${LIB_DIR}/${name}" ]]; then
    return 0
  fi
  if target="$(pick_first_existing "$@")"; then
    ln -sfn "${target}" "${LIB_DIR}/${name}"
    echo "[dm8-etl] odbc runtime: linked ${LIB_DIR}/${name} -> ${target}"
    return 0
  fi
  echo "[dm8-etl] odbc runtime: WARN missing ${name}; install openssl dev libs or provide DM8 bundled libs" >&2
  return 1
}

# Prefer common runtime locations; do NOT require sudo.
link_if_missing "libssl.so" \
  "/lib/x86_64-linux-gnu/libssl.so.3" \
  "/usr/lib/x86_64-linux-gnu/libssl.so.3" \
  "/lib/aarch64-linux-gnu/libssl.so.3" \
  "/usr/lib/aarch64-linux-gnu/libssl.so.3" \
  "/lib/x86_64-linux-gnu/libssl.so.1.1" \
  "/usr/lib/x86_64-linux-gnu/libssl.so.1.1" \
  "/lib/aarch64-linux-gnu/libssl.so.1.1" \
  "/usr/lib/aarch64-linux-gnu/libssl.so.1.1" \
  "/lib/x86_64-linux-gnu/libssl.so.1.0.0" \
  "/usr/lib/x86_64-linux-gnu/libssl.so.1.0.0" \
  "/lib/aarch64-linux-gnu/libssl.so.1.0.0" \
  "/usr/lib/aarch64-linux-gnu/libssl.so.1.0.0" \
  || true

link_if_missing "libcrypto.so" \
  "/lib/x86_64-linux-gnu/libcrypto.so.3" \
  "/usr/lib/x86_64-linux-gnu/libcrypto.so.3" \
  "/lib/aarch64-linux-gnu/libcrypto.so.3" \
  "/usr/lib/aarch64-linux-gnu/libcrypto.so.3" \
  "/lib/x86_64-linux-gnu/libcrypto.so.1.1" \
  "/usr/lib/x86_64-linux-gnu/libcrypto.so.1.1" \
  "/lib/aarch64-linux-gnu/libcrypto.so.1.1" \
  "/usr/lib/aarch64-linux-gnu/libcrypto.so.1.1" \
  "/lib/x86_64-linux-gnu/libcrypto.so.1.0.0" \
  "/usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0" \
  "/lib/aarch64-linux-gnu/libcrypto.so.1.0.0" \
  "/usr/lib/aarch64-linux-gnu/libcrypto.so.1.0.0" \
  || true

exit 0

