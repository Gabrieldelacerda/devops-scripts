#!/usr/bin/env bash
# Test SSL certificate monitoring

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/ssl-check.sh"

MOCK_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$MOCK_DIR"' EXIT

cat > "$MOCK_DIR/openssl" <<'EOF'
#!/usr/bin/env bash

case "$1" in
  s_client)
    if [[ "$3" == "missing.test:443" ]]; then
      exit 1
    fi
    printf '%s\n' "$3"
    ;;
  x509)
    read -r DOMAIN || exit 1

    case "$DOMAIN" in
      healthy.test:443)
        EXPIRY=$(date -u -d '+120 days' '+%b %d %H:%M:%S %Y GMT')
        ;;
      expiring.test:443)
        EXPIRY=$(date -u -d '+2 days' '+%b %d %H:%M:%S %Y GMT')
        ;;
      invalid.test:443)
        EXPIRY="invalid-date"
        ;;
      *)
        exit 1
        ;;
    esac

    printf 'notAfter=%s\n' "$EXPIRY"
    ;;
  *)
    exit 1
    ;;
esac
EOF

chmod +x "$MOCK_DIR/openssl" || exit 1


if ! OUTPUT=$(PATH="$MOCK_DIR:$PATH" THRESHOLD=30 bash "$SCRIPT" healthy.test); then
  echo "[FAIL] Healthy certificate should pass"
  exit 1
fi

if [[ "$OUTPUT" != "[ OK ] healthy.test certificate is valid for "* ]]; then
  echo "[FAIL] Unexpected healthy certificate output"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" THRESHOLD=30 bash "$SCRIPT" expiring.test); then
  echo "[FAIL] Expiring certificate should trigger an alert"
  exit 1
fi

if [[ "$OUTPUT" != "[ALERT] expiring.test certificate expires in "* ]]; then
  echo "[FAIL] Expected expiration alert"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" missing.test); then
  echo "[FAIL] Missing certificate should return failure"
  exit 1
fi

if [[ "$OUTPUT" != "[ERROR] Could not retrieve certificate for missing.test" ]]; then
  echo "[FAIL] Expected certificate retrieval error"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" invalid.test); then
  echo "[FAIL] Invalid certificate date should return failure"
  exit 1
fi

if [[ "$OUTPUT" != "[ERROR] Could not parse certificate expiry for invalid.test" ]]; then
  echo "[FAIL] Expected expiration parsing error"
  exit 1
fi

if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" healthy.test missing.test); then
  echo "[FAIL] Mixed certificate results should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ] healthy.test"* ]] ||
   [[ "$OUTPUT" != *"[ERROR] Could not retrieve certificate for missing.test"* ]]; then
  echo "[FAIL] Expected results for both domains"
  exit 1
fi

echo "[ OK ] ssl-check.sh tests passed"
