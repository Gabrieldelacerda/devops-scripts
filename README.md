# devops-scripts

A collection of Bash scripts for automating common Linux, DevOps, and system administration tasks.

The repository includes independent utilities for system monitoring, service and network checks, backups, log cleanup, Docker maintenance, SSL validation, and other routine operational tasks.

## Scripts

| Script | Description |
|---|---|
| `disk-check.sh` | Checks disk usage against a configurable threshold |
| `docker-cleanup.sh` | Removes stopped containers and unused Docker resources safely |
| `service-health.sh` | Checks whether specified services are running |
| `connectivity-check.sh` | Checks whether specified hosts respond to ICMP |
| `log-cleanup.sh` | Removes old log files from a configurable directory |
| `backup.sh` | Creates timestamped compressed backups of a specified directory |
| `cpu-check.sh` | Checks CPU usage against a configurable threshold |
| `port-check.sh` | Checks whether specified TCP ports are reachable |
| `uptime-check.sh` | Displays uptime and evaluates the 1-minute load average |
| `user-sessions.sh` | Displays active sessions and available login history information |
| `ssl-check.sh` | Checks SSL certificate expiration for specified domains |
| `process-monitor.sh` | Displays the processes consuming the most CPU and memory |
| `network-stats.sh` | Displays network interfaces, traffic counters, errors, drops, and listening sockets |
| `env-check.sh` | Verifies that required environment variables are set |
| `validate-scripts.sh` | Runs Bash syntax checks and ShellCheck across project scripts |

## Usage

Run any script with:

```bash
bash <script-name>.sh
```

Additional examples are available in [USAGE-EXAMPLES.md](USAGE-EXAMPLES.md).

## Validation

Validate Bash syntax and run ShellCheck locally:

```bash
bash validate-scripts.sh
```

These checks help identify syntax errors and potential scripting issues before changes are merged.

## Automated Testing

The repository includes automated functional tests covering:

- Environment variable validation
- Disk and CPU monitoring
- Load average monitoring
- TCP port connectivity
- ICMP connectivity
- Systemd service health
- SSL certificate expiration
- Backup creation and failure handling

Run the complete test suite with:

```bash
bash tests/run-tests.sh
```

The test suite verifies successful operations, invalid inputs, failure handling, and exit codes. Where appropriate, mocked commands are used to simulate failures safely and produce reproducible results.

## CI/CD — GitHub Actions

The GitHub Actions workflow automatically runs on pushes and pull requests. It can also be triggered manually.

The pipeline performs two main checks:

1. **Static validation:** Bash syntax checks and ShellCheck.
2. **Functional testing:** Automated tests covering operational scripts.

If validation or any functional test fails, the workflow reports a failure.

### Pipeline Execution

![Successful GitHub Actions pipeline](docs/screenshots/github-actions-pipeline.png)

### Automated Test Results

The latest documented test run completed with **9 test suites passed and 0 failed**.

![Automated test results](docs/screenshots/automated-tests-results.png)

These results demonstrate automated validation and testing integrated into the repository's development workflow.
