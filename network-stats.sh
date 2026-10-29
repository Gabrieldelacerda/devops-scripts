#!/usr/bin/env bash

ROUTE_TARGET=${ROUTE_TARGET-}

if [[ -n "$ROUTE_TARGET" ]] && [[ "$ROUTE_TARGET" == -* || "$ROUTE_TARGET" =~ [[:space:]/] ]]; then
  echo "[ERROR] Invalid ROUTE_TARGET: $ROUTE_TARGET"
  exit 1
fi

for CMD in ip ss awk; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found: $CMD"
    exit 1
  fi
done

echo "Network interfaces:"

if ! IP_OUTPUT=$(ip -br addr); then
  echo "[ERROR] Failed to retrieve network interfaces"
  exit 1
fi

if [[ -z "$IP_OUTPUT" ]]; then
  echo "[ERROR] Network interface output is empty"
  exit 1
fi

printf '%s\n' "$IP_OUTPUT"

echo ""
echo "Routing table:"

if ! ROUTE_OUTPUT=$(ip route show); then
  echo "[ERROR] Failed to retrieve routing table"
  exit 1
fi

if [[ -z "$ROUTE_OUTPUT" ]]; then
  echo "[INFO] No routes reported"
else
  printf '%s\n' "$ROUTE_OUTPUT"
fi

if [[ -n "$ROUTE_TARGET" ]]; then
  echo ""
  echo "Route to $ROUTE_TARGET:"

  if ! TARGET_ROUTE_OUTPUT=$(ip route get "$ROUTE_TARGET"); then
    echo "[ERROR] Failed to find route to $ROUTE_TARGET"
    exit 1
  fi

  if [[ -z "$TARGET_ROUTE_OUTPUT" ]]; then
    echo "[ERROR] Route lookup returned no data for $ROUTE_TARGET"
    exit 1
  fi

  printf '%s\n' "$TARGET_ROUTE_OUTPUT"
fi

echo ""
echo "Network statistics:"

if ! STATS_OUTPUT=$(awk 'NR>2 {
  gsub(":", "", $1)
  print $1,
        "RX:", $2, "bytes",
        "errors:", $4,
        "drops:", $5,
        "| TX:", $10, "bytes",
        "errors:", $12,
        "drops:", $13
}' /proc/net/dev); then
  echo "[ERROR] Failed to retrieve network statistics"
  exit 1
fi

if [[ -z "$STATS_OUTPUT" ]]; then
  echo "[ERROR] Network statistics output is empty"
  exit 1
fi

printf '%s\n' "$STATS_OUTPUT"

echo ""
echo "Listening sockets:"

if ! SOCKET_OUTPUT=$(ss -tuln); then
  echo "[ERROR] Failed to retrieve listening sockets"
  exit 1
fi

if [[ -z "$SOCKET_OUTPUT" ]]; then
  echo "[ERROR] Listening sockets output is empty"
  exit 1
fi

printf '%s\n' "$SOCKET_OUTPUT"
