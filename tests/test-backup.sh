#!/usr/bin/env bash
# Test backup creation and failure handling

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/backup.sh"

TEST_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$TEST_DIR"' EXIT

SOURCE="$TEST_DIR/source"
DEST="$TEST_DIR/backups"

mkdir -p "$SOURCE" || exit 1
printf 'Test backup content\n' > "$SOURCE/example.txt"

# Test 1: Successful backup
if ! OUTPUT=$(bash "$SCRIPT" "$SOURCE" "$DEST" 2>&1); then
  echo "[FAIL] Backup should succeed"
  exit 1
fi

BACKUP_FILE=$(find "$DEST" -maxdepth 1 -type f -name 'backup_*.tar.gz' -print -quit)

if [[ -z "$BACKUP_FILE" ]] || ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Valid backup archive was not created"
  exit 1
fi

if ! tar -tzf "$BACKUP_FILE" | grep -q '/example.txt$'; then
  echo "[FAIL] Backup archive is missing the source file"
  exit 1
fi

# Test 2: Missing source directory
if OUTPUT=$(bash "$SCRIPT" "$TEST_DIR/missing" "$DEST" 2>&1); then
  echo "[FAIL] Missing source should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] Source directory does not exist:"* ]]; then
  echo "[FAIL] Expected missing source error"
  exit 1
fi

# Test 3: Destination creation failure
MOCK_MKDIR="$TEST_DIR/mock-mkdir"
mkdir -p "$MOCK_MKDIR" || exit 1

cat > "$MOCK_MKDIR/mkdir" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$MOCK_MKDIR/mkdir" || exit 1

if OUTPUT=$(PATH="$MOCK_MKDIR:$PATH" bash "$SCRIPT" "$SOURCE" "$TEST_DIR/blocked" 2>&1); then
  echo "[FAIL] Destination creation failure should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] Could not create destination directory:"* ]]; then
  echo "[FAIL] Expected destination creation error"
  exit 1
fi

# Test 4: Failed backup must remove incomplete archive
MOCK_TAR="$TEST_DIR/mock-tar"
mkdir -p "$MOCK_TAR" || exit 1

cat > "$MOCK_TAR/tar" <<'EOF'
#!/usr/bin/env bash
printf 'incomplete backup' > "$2"
exit 1
EOF

chmod +x "$MOCK_TAR/tar" || exit 1

FAILED_DEST="$TEST_DIR/failed-backups"

if OUTPUT=$(PATH="$MOCK_TAR:$PATH" bash "$SCRIPT" "$SOURCE" "$FAILED_DEST" 2>&1); then
  echo "[FAIL] Failed tar operation should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] Backup failed for"* ]]; then
  echo "[FAIL] Expected backup failure message"
  exit 1
fi

if find "$FAILED_DEST" -maxdepth 1 -type f -name 'backup_*.tar.gz' | grep -q .; then
  echo "[FAIL] Incomplete backup was not removed"
  exit 1
fi

echo "[ OK ] backup.sh tests passed"
