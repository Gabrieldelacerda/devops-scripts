
#backup.sh Create a compressed backup of a directory

SOURCE="/var/www"
DEST="/tmp/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$DEST"
tar -czf "$DEST/backup_$TIMESTAMP.tar.gz" "$SOURCE"
echo "Backup saved to $DEST/backup_$TIMESTAMP.tar.gz"
