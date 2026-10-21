#!/usr/bin/env bash

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/service-health.sh"

MOCK_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$MOCK_DIR"' EXIT

cat > "$MOCK_DIR/systemctl" <<'EOF'
#!/usr/bin/env bash

case "$1" in
  show)
    case "$2" in
      active|inactive|socket) echo "loaded" ;;
      missing) echo "not-found" ;;
      unavailable)
        echo "Failed to connect to bus" >&2
        exit 1
        ;;
      *) exit 1 ;;
    esac
    ;;
  is-active)
    [[ "$3" == "active" || "$3" == "socket" ]]
    ;;
  is-enabled)
    [[ "$3" == "active" || "$3" == "socket.socket" ]]
    ;;
  *)
    exit 2
    ;;
esac
EOF

chmod +x "$MOCK_DIR/systemctl" || exit 1

check_service() {
  local service="$1"
  local expected_status="$2"
  local expected_output="$3"
  local output status

  if output=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" "$service"); then
    status=0
  else
    status=$?
  fi

  if [[ "$status" -ne "$expected_status" || "$output" != "$expected_output" ]]; then
    echo "[FAIL] Unexpected result for $service"
    echo "Output: $output"
    echo "Exit code: $status"
    return 1
  fi
}

check_service active 0 "active is running (boot: enabled)" || exit 1
check_service inactive 1 "inactive is NOT running (boot: disabled)" || exit 1
check_service missing 1 "[ERROR] missing was not found" || exit 1
check_service socket 0 "socket is running (boot: socket-activated)" || exit 1
check_service unavailable 1 "[ERROR] Could not inspect unavailable" || exit 1

echo "[ OK ] service-health.sh tests passed"
