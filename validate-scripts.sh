#!/usr/bin/env bash

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[ERROR] ShellCheck is required"
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

if [ "$#" -gt 0 ]; then
  SCRIPTS=()

  for SCRIPT in "$@"; do
    if [ ! -f "$SCRIPT" ]; then
      echo "[ERROR] Script not found: $SCRIPT"
      exit 1
    fi

    if [[ "$SCRIPT" != *.sh ]]; then
      echo "[ERROR] Expected a .sh file: $SCRIPT"
      exit 1
    fi

    SCRIPTS+=("$SCRIPT")
  done
else
  shopt -s nullglob
  SCRIPTS=("$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/tests/*.sh)
  shopt -u nullglob
fi

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
