#!/bin/bash

REQUIRED=("HOME" "PATH" "USER" "SHELL")

for VAR in "${REQUIRED[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "[MISSING] $VAR is not set"
  else
    echo "$VAR is set to: ${!VAR}"
  fi
done
