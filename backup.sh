#!/usr/bin/env bash

SOURCE=${1:-/var/www}
DEST=${2:-/tmp/backups}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ ! -d "$SOURCE" ]; then
  echo "[ERROR] Source directory does not exist: $SOURCE"
  exit 1
fi

if ! mkdir -p "$DEST"; then
  echo "[ERROR] Could not create destination directory: $DEST"
  exit 1
fi

if ! BACKUP_FILE=$(mktemp "$DEST/backup_${TIMESTAMP}_XXXXXX.tar.gz"); then
  echo "[ERROR] Could not create a unique backup file in $DEST"
  exit 1
fi

if ! tar -czf "$BACKUP_FILE" "$SOURCE"; then
  echo "[ERROR] Backup failed for $SOURCE"
  rm -f -- "$BACKUP_FILE"
  exit 1
fi

if ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
  echo "[ERROR] Backup verification failed for $SOURCE"
  rm -f -- "$BACKUP_FILE"
  exit 1
fi

echo "[ OK ] Backup saved to $BACKUP_FILE"
