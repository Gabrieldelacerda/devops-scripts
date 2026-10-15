#!/usr/bin/env bash
# Validate all Bash scripts, including automated tests

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[ERROR] ShellCheck is required"
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

shopt -s nullglob
SCRIPTS=("$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/tests/*.sh)
shopt -u nullglob

if [ "${#SCRIPTS[@]}" -eq 0 ]; then
  echo "[ERROR] No Bash scripts found"
  exit 1
fi

FAILED=0

for SCRIPT in "${SCRIPTS[@]}"; do
  echo "Checking ${SCRIPT##*/}..."

  if ! bash -n "$SCRIPT"; then
    echo "[ERROR] Syntax check failed: $SCRIPT"
    FAILED=$((FAILED + 1))
    continue
  fi

  if ! shellcheck "$SCRIPT"; then
    echo "[ERROR] ShellCheck failed: $SCRIPT"
    FAILED=$((FAILED + 1))
  fi
done

if [ "$FAILED" -gt 0 ]; then
  echo "[ERROR] Validation failed: $FAILED of ${#SCRIPTS[@]} scripts failed"
  exit 1
fi

echo "[ OK ] All ${#SCRIPTS[@]} scripts passed validation"
