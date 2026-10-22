# devops-scripts

A collection of Bash scripts for automating common Linux, DevOps, and system administration tasks.

The project focuses on infrastructure operations, reliable automation, troubleshooting, error handling, and automated testing.

## Scripts

| Script | Description |
|---|---|
| `disk-check.sh` | Monitors disk usage against a configurable threshold |
| `docker-cleanup.sh` | Cleans up unused Docker resources with confirmation |
| `service-health.sh` | Checks systemd services, boot configuration, and command failures |
| `connectivity-check.sh` | Checks ICMP connectivity and reports operational errors |
| `log-cleanup.sh` | Removes old log files, with an optional dry-run mode |
| `backup.sh` | Creates compressed backups with unique filenames |
| `cpu-check.sh` | Monitors CPU usage, validates CPU counters, and detects sampling errors |
| `port-check.sh` | Checks TCP connectivity with configurable connection timeouts |
| `uptime-check.sh` | Reports system uptime, evaluates load average, and handles collection failures |
| `user-sessions.sh` | Displays active sessions and login history with error handling |
| `ssl-check.sh` | Checks SSL certificate expiration and detects TLS connection failures |
| `process-monitor.sh` | Displays top CPU and memory processes and detects collection failures |
| `network-stats.sh` | Reports interfaces, traffic statistics, and listening sockets with error detection |
| `env-check.sh` | Validates required environment variables without exposing their values |
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

### Backups

Create a compressed backup:

```bash
bash backup.sh /path/to/source /path/to/backups
```

Backup filenames combine a timestamp with a unique suffix, preventing files created within the same second from overwriting one another.

Backup integrity and restoration procedures are documented in [Backup Verification](docs/backup-verification.md).

### Connectivity Checks

Check ICMP connectivity to specific hosts:

```bash
bash connectivity-check.sh github.com 1.1.1.1
```

The script distinguishes unreachable hosts, invalid inputs, and operational errors reported by `ping`.

### TCP Port Checks

Check TCP connectivity:

```bash
bash port-check.sh github.com 443
```

Configure the connection timeout:

```bash
CONNECT_TIMEOUT=5 bash port-check.sh github.com 443
```

The default timeout is 2 seconds. Custom values from 1 to 30 seconds are supported.

### CPU Monitoring

Check CPU usage against a threshold:

```bash
THRESHOLD=80 bash cpu-check.sh
```

The script samples CPU counters, validates the measurements, and reports alerts when usage reaches the configured threshold.

### SSL Certificate Monitoring

Check certificate expiration:

```bash
THRESHOLD=30 bash ssl-check.sh github.com
```

The script reports certificates approaching expiration and detects errors during TLS connection and certificate retrieval.

It is designed for expiration monitoring, not full certificate chain validation.

## Automated Testing

The repository includes **16 automated test suites** covering:

- Environment variable validation, including invalid variable names
- Disk usage, CPU usage, and load average monitoring
- CPU counter validation and sampling failures
- TCP connectivity, port boundaries, and configurable timeouts
- ICMP connectivity and operational errors
- Systemd service health, missing services, and command failures
- SSL certificate expiration and TLS connection failures
- Backup creation, restoration, and error handling
- Docker cleanup and cancellation
- Log cleanup, including dry-run behavior
- Network monitoring, empty outputs, and command failures
- Process monitoring, input validation, and collection failures
- User session monitoring and command failure handling
- Test runner behavior and failure reporting
- Bash validator behavior and error detection

Tests cover successful operations, invalid inputs, boundary conditions, failure scenarios, and exit codes.

Mocked commands and controlled test inputs are used where appropriate to simulate failures safely and produce reproducible results.

Run the complete test suite:

```bash
bash tests/run-tests.sh
```

Successful execution:

```text
Results: 16 passed, 0 failed
```

## Validation and CI/CD

Validate Bash syntax and run ShellCheck across the repository:

```bash
bash validate-scripts.sh
```

Validate specific scripts:

```bash
bash validate-scripts.sh backup.sh network-stats.sh
```

GitHub Actions automatically runs static validation and functional tests on pushes and pull requests. The workflow also supports manual execution.

The pipeline uses read-only repository permissions and reports failures when validation or tests do not pass.

### GitHub Actions Pipeline

![Successful GitHub Actions pipeline](docs/screenshots/github-actions-pipeline.png)

### Automated Test Results

The screenshot below documents an earlier successful run with 9 passing suites. The project has since expanded to 16 automated test suites.

![Automated test results](docs/screenshots/automated-tests-results.png)

## Operational Documentation

Additional guides based on Linux infrastructure and application troubleshooting practices:

- [Backup Verification](docs/backup-verification.md) — Archive inspection, integrity checks, and restoration procedures
- [Application Troubleshooting](docs/application-troubleshooting.md) — HTTP 502 errors, Kubernetes CrashLoopBackOff, logs, and incident investigation

## Project Goals

This project is part of my hands-on Cloud/DevOps learning journey, with an emphasis on:

- Linux infrastructure operations
- Bash automation and troubleshooting
- Reliable scripting and failure handling
- Automated testing and CI/CD
- Monitoring and operational diagnostics
- Maintainable infrastructure tooling
