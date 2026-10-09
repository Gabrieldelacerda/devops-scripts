# devops-scripts

A collection of Bash scripts for automating common Linux, DevOps, and system administration tasks.

The repository includes independent utilities for system monitoring, service and network checks, backups, log cleanup, Docker maintenance, SSL validation, and other routine operational tasks.

## Scripts

| Script                  | Description                                                                  |
| ----------------------- | ---------------------------------------------------------------------------- |
| `disk-check.sh`         | Checks disk usage against a configurable threshold                           |
| `docker-cleanup.sh`     | Removes stopped containers and unused Docker resources safely                |
| `service-health.sh`     | Checks whether specified services are running                                |
| `connectivity-check.sh` | Checks whether specified hosts are reachable                                 |
| `log-cleanup.sh`        | Removes old log files from a configurable directory                          |
| `backup.sh`             | Creates timestamped compressed backups of a specified directory              |
| `cpu-check.sh`          | Checks CPU usage against a configurable threshold                            |
| `port-check.sh`         | Checks whether specified ports are open on a host                            |
| `uptime-check.sh`       | Displays uptime and evaluates the 1-minute load average                       |
| `user-sessions.sh`      | Displays active sessions and available login history information             |
| `ssl-check.sh`          | Checks SSL certificate expiration for specified domains                      |
| `process-monitor.sh`    | Displays the processes consuming the most CPU and memory                     |
| `network-stats.sh`      | Displays network interfaces, traffic counters, errors, drops, and listening sockets |
| `env-check.sh`          | Verifies that required environment variables are set                         |
| `validate-scripts.sh`   | Runs Bash syntax checks and ShellCheck across all scripts                     |

## Usage

Run any script with:

```bash
bash <script-name>.sh
```

## Validation

Validate all Bash scripts locally with:

```bash
bash validate-scripts.sh
```

Validation checks Bash syntax with `bash -n` and static analysis with `shellcheck`, helping catch issues before changes are merged.

The same validation runs automatically through GitHub Actions on pushes and pull requests.
