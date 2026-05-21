# devops-scripts

A growing collection of bash scripts automating common DevOps and sysadmin tasks.

## Scripts

| Script | Description |
|--------|-------------|
| `disk-check.sh` | Alerts when disk usage exceeds 80% threshold |
| `docker-cleanup.sh` | Prunes stopped containers, unused images, and dangling volumes |
| `service-health.sh` | Checks if services are running |
| `connectivity-check.sh` | Checks if hosts are reachable |
| `log-cleanup.sh` | Deletes log files older than 30 days |
| `backup.sh` | Creates a compressed backup of a directory with a timestamp |
| `cpu-check.sh` | Alerts when CPU usage exceeds 80% threshold |
| `port-check.sh` | Checks if ports are open on a given host |

## Usage

```bash
bash scripts/<script-name>.sh
```
