#!/bin/bash

REQUIRED=("HOME" "PATH" "USER" "SHELL")
MISSING=0

for VAR in "${REQUIRED[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "[MISSING] $VAR is not set"
    MISSING=$((MISSING + 1))
  else
    echo "$VAR is set to: ${!VAR}"
  fi
done

if [ "$MISSING" -gt 0 ]; then
  exit 1
fi

exit 0
