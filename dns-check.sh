#!/usr/bin/env bash

DNS_TYPE=${DNS_TYPE-A}
DNS_TIMEOUT=${DNS_TIMEOUT-2}

if ! [[ "$DNS_TYPE" =~ ^(A|AAAA|CNAME|MX|NS|TXT)$ ]]; then
  echo "[ERROR] DNS_TYPE must be A, AAAA, CNAME, MX, NS or TXT" >&2
  exit 1
fi

if ! [[ "$DNS_TIMEOUT" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
  echo "[ERROR] DNS_TIMEOUT must be an integer between 1 and 30" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <domain> [domain ...]" >&2
  exit 1
fi

if ! command -v dig >/dev/null 2>&1; then
  echo "[ERROR] Required command not found: dig" >&2
  exit 1
fi

valid_domain() {
  local NAME="${1%.}"
  local LABEL
  local IFS=.
  local -a LABELS

  if [[ -z "$NAME" || ${#NAME} -gt 253 || "$NAME" == *. || "$NAME" == *..* ]]; then
    return 1
  fi

  if ! [[ "$NAME" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    return 1
  fi

  read -r -a LABELS <<< "$NAME"

  for LABEL in "${LABELS[@]}"; do
    if [[ -z "$LABEL" || ${#LABEL} -gt 63 || "$LABEL" == -* || "$LABEL" == *- ]]; then
      return 1
    fi
  done

  return 0
}

FAILED=0

for DOMAIN in "$@"; do
  if ! valid_domain "$DOMAIN"; then
    echo "[INVALID] Invalid domain: $DOMAIN"
    FAILED=1
    continue
  fi

  if RESULT=$(dig "+time=$DNS_TIMEOUT" +tries=1 +short "$DOMAIN" "$DNS_TYPE" 2>/dev/null); then
    if [[ -n "$RESULT" ]]; then
      echo "[FOUND] $DOMAIN $DNS_TYPE"
      printf '%s\n' "$RESULT"
    else
      echo "[MISSING] No $DNS_TYPE records found for $DOMAIN"
      FAILED=1
    fi
  else
    echo "[ERROR] DNS lookup failed for $DOMAIN"
    FAILED=1
  fi
done

exit "$FAILED"
