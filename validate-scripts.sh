#!/usr/bin/env bash

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[ERROR] ShellCheck is required"
  exit 1
fi

FAILED=0

for SCRIPT in *.sh; do
  echo "Checking $SCRIPT..."

  if ! bash -n "$SCRIPT"; then
    echo "[ERROR] Syntax check failed: $SCRIPT"
    FAILED=1
    continue
  fi

  if ! shellcheck "$SCRIPT"; then
    echo "[ERROR] ShellCheck failed: $SCRIPT"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo "[ERROR] Validation failed"
  exit 1
fi

echo "[ OK ] All scripts passed validation"
