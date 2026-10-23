#!/usr/bin/env bash

if [ "$#" -gt 0 ]; then
  REQUIRED=("$@")
else
  REQUIRED=("HOME" "PATH" "USER" "SHELL")
fi

FAILED=0

for VAR in "${REQUIRED[@]}"; do
  if ! [[ "$VAR" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "[ERROR] Invalid variable name: $VAR" >&2
    FAILED=1
    continue
  fi

  DECLARATION=$(declare -p "$VAR" 2>/dev/null || true)

  if [[ ! "$DECLARATION" =~ ^declare[[:space:]]+-[^[:space:]]*x[[:space:]] ]] ||
     [[ -z "${!VAR:-}" ]]; then
    echo "[MISSING] $VAR is not set"
    FAILED=1
  else
    echo "[ OK ] $VAR is set"
  fi
done

exit "$FAILED"
