#!/usr/bin/env bash

#backup.sh Create a compressed backup of a directory

SOURCE=${1:-/var/www}
DEST=${2:-/tmp/backups}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ ! -d "$SOURCE" ]; then
  echo "[ERROR] Source directory does not exist: $SOURCE"
  exit 1
fi

mkdir -p "$DEST"
tar -czf "$DEST/backup_$TIMESTAMP.tar.gz" "$SOURCE"
echo "Backup saved to $DEST/backup_$TIMESTAMP.tar.gz"
