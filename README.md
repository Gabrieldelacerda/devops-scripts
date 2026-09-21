# devops-scripts

A collection of Bash scripts for automating common Linux, DevOps, and system administration tasks.

The scripts cover basic monitoring, service and network checks, backups, log cleanup, Docker maintenance, and other routine operations.

## Scripts

| Script                  | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| `disk-check.sh`         | Alerts when disk usage exceeds an 80% threshold                      |
| `docker-cleanup.sh`     | Removes stopped containers and unused Docker resources               |
| `service-health.sh`     | Checks whether specified services are running                        |
| `connectivity-check.sh` | Checks whether hosts are reachable                                   |
| `log-cleanup.sh`        | Removes log files older than 30 days                                 |
| `backup.sh`             | Creates timestamped compressed backups of a directory                |
| `cpu-check.sh`          | Alerts when CPU usage exceeds an 80% threshold                       |
| `port-check.sh`         | Checks whether ports are open on a given host                        |
| `memory-check.sh`       | Alerts when memory usage exceeds an 80% threshold                    |
| `uptime-check.sh`       | Displays system uptime and load average                              |
| `user-sessions.sh`      | Displays active sessions, logged-in users, and failed login attempts |
| `ssl-check.sh`          | Checks whether SSL certificates are approaching expiration           |
| `process-monitor.sh`    | Displays the processes consuming the most CPU and memory             |
| `network-stats.sh`      | Displays network interface statistics and bandwidth usage            |
| `env-check.sh`          | Verifies that required environment variables are set                 |

## Usage

```bash
bash scripts/<script-name>.sh
```

Each script can also be inspected individually for its available parameters and behavior.
