#!/usr/bin/env bash

#backup.sh Create a compressed backup of a directory

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

BACKUP_FILE="$DEST/backup_$TIMESTAMP.tar.gz"

if tar -czf "$BACKUP_FILE" "$SOURCE"; then
  echo "Backup saved to $BACKUP_FILE"
else
  echo "[ERROR] Backup failed for $SOURCE"
  exit 1
fi
