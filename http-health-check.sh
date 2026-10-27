#!/usr/bin/env bash

HTTP_EXPECTED_STATUS=${HTTP_EXPECTED_STATUS-200}
HTTP_TIMEOUT=${HTTP_TIMEOUT-5}

if [[ ! "$HTTP_EXPECTED_STATUS" =~ ^[1-5][0-9]{2}$ ]]; then
  echo "[ERROR] HTTP_EXPECTED_STATUS must be a valid HTTP status code" >&2
  exit 1
fi

if [[ ! "$HTTP_TIMEOUT" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
  echo "[ERROR] HTTP_TIMEOUT must be an integer between 1 and 30" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <url> [url ...]" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[ERROR] Required command not found: curl" >&2
  exit 1
fi

FAILED=0

for URL in "$@"; do
  if ! [[ "$URL" =~ ^https?://[^[:space:]]+$ ]]; then
    echo "[INVALID] Invalid HTTP URL: $URL"
    FAILED=1
    continue
  fi

  if STATUS=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time "$HTTP_TIMEOUT" -- "$URL"); then
    if [[ "$STATUS" == "$HTTP_EXPECTED_STATUS" ]]; then
      echo "[ OK ] $URL returned HTTP $STATUS"
    else
      echo "[ALERT] $URL returned HTTP $STATUS (expected $HTTP_EXPECTED_STATUS)"
      FAILED=1
    fi
  else
    EXIT_CODE=$?
    REASON=""

    case "$EXIT_CODE" in
      6) REASON="DNS resolution failed" ;;
      7) REASON="Connection failed" ;;
      28) REASON="Request timed out" ;;
      35) REASON="TLS handshake failed" ;;
      60) REASON="TLS certificate verification failed" ;;
    esac

    if [[ -n "$REASON" ]]; then
      echo "[ERROR] Request failed for $URL (curl exit code: $EXIT_CODE: $REASON)"
    else
      echo "[ERROR] Request failed for $URL (curl exit code: $EXIT_CODE)"
    fi

    FAILED=1
  fi
done

exit "$FAILED"
