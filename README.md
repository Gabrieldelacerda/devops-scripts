
# devops-scripts

A collection of Bash scripts for automating common Linux, DevOps, and system administration tasks.

The project focuses on practical infrastructure operations, automation reliability, error handling, and automated testing.

## Scripts

| Script | Description |
|---|---|
| `disk-check.sh` | Monitors disk usage against a configurable threshold |
| `docker-cleanup.sh` | Cleans up unused Docker resources with confirmation |
| `service-health.sh` | Checks the status of systemd services |
| `connectivity-check.sh` | Tests ICMP connectivity to specified hosts |
| `log-cleanup.sh` | Removes old log files, with an optional dry-run mode |
| `backup.sh` | Creates timestamped compressed directory backups |
| `cpu-check.sh` | Monitors CPU usage against a configurable threshold |
| `port-check.sh` | Checks TCP port connectivity |
| `uptime-check.sh` | Reports system uptime and evaluates load average |
| `user-sessions.sh` | Displays active sessions and login history |
| `ssl-check.sh` | Checks SSL certificate expiration |
| `process-monitor.sh` | Displays processes with the highest CPU and memory usage |
| `network-stats.sh` | Reports interfaces, traffic statistics, and listening sockets |
| `env-check.sh` | Verifies required environment variables without exposing their values |
| `validate-scripts.sh` | Performs Bash syntax checks and ShellCheck validation |

## Usage

Run a script with:

```bash
bash <script-name>.sh
```

For additional examples, see [USAGE-EXAMPLES.md](USAGE-EXAMPLES.md).

### Log Cleanup — Dry Run

Preview which log files would be removed:

```bash
bash log-cleanup.sh /path/to/logs 7 --dry-run
```

The dry-run mode lists matching files without deleting them.

To perform the cleanup:

```bash
bash log-cleanup.sh /path/to/logs 7
```

## Automated Testing

The repository includes **15 automated test suites** covering:

- Environment variable validation
- Disk, CPU, and load average monitoring
- TCP and ICMP connectivity
- Systemd service health
- SSL certificate expiration
- Backup creation and error handling
- Docker cleanup and cancellation
- Log cleanup, including dry-run behavior
- Network monitoring and command failures
- Process monitoring and input validation
- User session monitoring
- Test runner behavior and failure reporting

Tests cover successful operations, invalid inputs, failure scenarios, and exit codes.

Mocked commands are used where appropriate to simulate failures safely and produce reproducible results.

Run all tests:

```bash
bash tests/run-tests.sh
```

Latest locally verified result:

```text
Results: 15 passed, 0 failed
```

## Validation and CI/CD

Validate Bash syntax and run ShellCheck:

```bash
bash validate-scripts.sh
```

GitHub Actions automatically runs validation and functional tests on pushes and pull requests. The workflow also supports manual execution.

The pipeline uses read-only repository permissions and reports failures when validation or tests do not pass.

### GitHub Actions Pipeline

![Successful GitHub Actions pipeline](docs/screenshots/github-actions-pipeline.png)

### Automated Test Results

The screenshot below documents an earlier successful run with 9 passing suites. The project has since expanded to 15 automated test suites.

![Automated test results](docs/screenshots/automated-tests-results.png)

## Project Goals

This project is part of my hands-on Cloud/DevOps learning journey, with an emphasis on:

- Linux infrastructure operations
- Bash automation and troubleshooting
- Reliable scripting and failure handling
- Automated testing and CI/CD
- Maintainable operational tooling
