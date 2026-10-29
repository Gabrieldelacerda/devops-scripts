#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/backup.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

SOURCE="$TEST_DIR/source directory"
DEST="$TEST_DIR/backup archives"
RESTORE="$TEST_DIR/restored"

mkdir -p "$SOURCE/nested directory" "$RESTORE"
printf 'Test backup content\n' > "$SOURCE/example.txt"
printf 'First line\nSecond line\n' > "$SOURCE/nested directory/config file.txt"
printf 'Hidden file content\n' > "$SOURCE/.hidden"
printf '\000\001\377\000' > "$SOURCE/data.bin"

if ! OUTPUT=$(bash "$SCRIPT" "$SOURCE" "$DEST" 2>&1); then
  fail "Backup should succeed"
fi

[[ "$OUTPUT" == *"[ OK ] Backup saved to"* ]] ||
  fail "Backup success message was not displayed"

BACKUP_FILE=$(find "$DEST" -maxdepth 1 -type f -name 'backup_*.tar.gz' -print -quit)

[[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]] ||
  fail "Backup archive was not created"

tar -tzf "$BACKUP_FILE" >/dev/null 2>&1 ||
  fail "Backup archive is invalid"

tar -xzf "$BACKUP_FILE" -C "$RESTORE" >/dev/null 2>&1 ||
  fail "Backup archive could not be restored"

RESTORED_SOURCE="$RESTORE/${SOURCE#/}"

for FILE in "example.txt" "nested directory/config file.txt" ".hidden" "data.bin"; do
  [[ -f "$RESTORED_SOURCE/$FILE" ]] ||
    fail "Restored file is missing: $FILE"

  cmp -s -- "$SOURCE/$FILE" "$RESTORED_SOURCE/$FILE" ||
    fail "Restored file differs from original: $FILE"
done

if OUTPUT=$(bash "$SCRIPT" "$TEST_DIR/missing" "$DEST" 2>&1); then
  fail "Missing source should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] Source directory does not exist:"* ]] ||
  fail "Expected missing source error"

MOCK_MKDIR="$TEST_DIR/mock-mkdir"
mkdir -p "$MOCK_MKDIR"

cat > "$MOCK_MKDIR/mkdir" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK

chmod +x "$MOCK_MKDIR/mkdir"

if OUTPUT=$(PATH="$MOCK_MKDIR:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$TEST_DIR/blocked" 2>&1); then
  fail "Destination creation failure should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] Could not create destination directory:"* ]] ||
  fail "Expected destination creation error"

MOCK_MKTEMP="$TEST_DIR/mock-mktemp"
mkdir -p "$MOCK_MKTEMP"

cat > "$MOCK_MKTEMP/mktemp" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK

chmod +x "$MOCK_MKTEMP/mktemp"

if OUTPUT=$(PATH="$MOCK_MKTEMP:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$TEST_DIR/reservation-failed" 2>&1); then
  fail "Failure to create a unique backup file should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Could not create a unique backup file"* ]] ||
  fail "Expected unique filename creation error"

MOCK_TAR="$TEST_DIR/mock-tar"
mkdir -p "$MOCK_TAR"

cat > "$MOCK_TAR/tar" <<'MOCK'
#!/usr/bin/env bash
printf 'incomplete backup' > "$2"
exit 1
MOCK

chmod +x "$MOCK_TAR/tar"

FAILED_DEST="$TEST_DIR/failed-backups"

if OUTPUT=$(PATH="$MOCK_TAR:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$FAILED_DEST" 2>&1); then
  fail "Failed tar operation should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] Backup failed for"* ]] ||
  fail "Expected backup failure message"

if find "$FAILED_DEST" -maxdepth 1 -type f \
  -name 'backup_*.tar.gz' | grep -q .; then
  fail "Incomplete backup was not removed"
fi

MOCK_CORRUPT_TAR="$TEST_DIR/mock-corrupt-tar"
mkdir -p "$MOCK_CORRUPT_TAR"

cat > "$MOCK_CORRUPT_TAR/tar" <<'MOCK'
#!/usr/bin/env bash

if [[ "$1" == '-czf' ]]; then
  printf 'invalid archive\n' > "$2"
  exit 0
fi

exec "$REAL_TAR" "$@"
MOCK

chmod +x "$MOCK_CORRUPT_TAR/tar"

CORRUPT_DEST="$TEST_DIR/corrupt-backups"
REAL_TAR=$(command -v tar)

if OUTPUT=$(REAL_TAR="$REAL_TAR" PATH="$MOCK_CORRUPT_TAR:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$CORRUPT_DEST" 2>&1); then
  fail "Corrupted archive should not be reported as successful"
fi

[[ "$OUTPUT" == *"[ERROR] Backup verification failed for"* ]] ||
  fail "Expected backup verification error"

if find "$CORRUPT_DEST" -maxdepth 1 -type f \
  -name 'backup_*.tar.gz' | grep -q .; then
  fail "Corrupted archive was not removed"
fi

MOCK_DATE="$TEST_DIR/mock-date"
mkdir -p "$MOCK_DATE"

cat > "$MOCK_DATE/date" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' '20261020_120000'
MOCK

chmod +x "$MOCK_DATE/date"

COLLISION_DEST="$TEST_DIR/same-second-backups"
printf 'first version\n' > "$SOURCE/example.txt"

if ! OUTPUT=$(PATH="$MOCK_DATE:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$COLLISION_DEST" 2>&1); then
  fail "First backup with fixed timestamp should succeed"
fi

FIRST_BACKUP=$(find "$COLLISION_DEST" -maxdepth 1 -type f \
  -name 'backup_*.tar.gz' -print -quit)

[[ -n "$FIRST_BACKUP" ]] ||
  fail "First archive was not created"

printf 'second version\n' > "$SOURCE/example.txt"

if ! OUTPUT=$(PATH="$MOCK_DATE:$PATH" \
  bash "$SCRIPT" "$SOURCE" "$COLLISION_DEST" 2>&1); then
  fail "Second backup with fixed timestamp should succeed"
fi

SECOND_BACKUP=$(find "$COLLISION_DEST" -maxdepth 1 -type f \
  -name 'backup_*.tar.gz' ! -path "$FIRST_BACKUP" -print -quit)

[[ -n "$SECOND_BACKUP" ]] ||
  fail "Second backup replaced the first archive"

FIRST_CONTENT=$(tar -xOzf "$FIRST_BACKUP" \
  "${SOURCE#/}/example.txt" 2>/dev/null) ||
  fail "Could not read the first backup"

SECOND_CONTENT=$(tar -xOzf "$SECOND_BACKUP" \
  "${SOURCE#/}/example.txt" 2>/dev/null) ||
  fail "Could not read the second backup"

[[ "$FIRST_CONTENT" == 'first version' ]] ||
  fail "The first archive was overwritten"

[[ "$SECOND_CONTENT" == 'second version' ]] ||
  fail "The second archive has incorrect contents"

echo "[ OK ] backup.sh tests passed"
