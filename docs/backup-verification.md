# Backup Verification

A successful backup should be verified before it is considered reliable.

## Verification Procedure

1. Create an archive using `backup.sh`.
2. Confirm that the backup file exists.
3. Inspect the archive using `tar -tzf`.
4. Extract the archive into a temporary directory.
5. Compare restored files with the original data.

## Example Commands

- Create a backup: `bash backup.sh source backups`
- Inspect an archive: `tar -tzf backup.tar.gz`
- Extract an archive: `tar -xzf backup.tar.gz -C /tmp/backup-check`

## Reliability

Backup automation should verify exit codes, archive integrity, and restoration results. Periodic restoration tests help identify problems before a backup is needed.
