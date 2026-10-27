
# DevOps Scripts

A collection of Bash scripts developed to automate Linux administration, monitor system health, troubleshoot infrastructure issues, and practice DevOps engineering principles.

This repository is part of my hands-on learning journey toward Cloud Engineering, DevOps, and Site Reliability Engineering (SRE).

The focus is on building practical, reusable tools with input validation, error handling, automated testing, and continuous integration.

## Tech Stack

- **Operating System:** Linux
- **Scripting:** Bash
- **Containers:** Docker
- **Version Control:** Git and GitHub
- **CI:** GitHub Actions
- **Code Quality:** ShellCheck and Bash syntax validation
- **Testing:** Automated Bash tests with mocked system commands

## Scripts

### System Monitoring

| Script | Description |
|---|---|
| `cpu-check.sh` | Monitors CPU utilization and identifies high usage. |
| `disk-check.sh` | Checks filesystem usage against a configurable threshold. |
| `uptime-check.sh` | Retrieves system uptime and load information. |
| `process-monitor.sh` | Checks whether specified processes are running. |
| `network-stats.sh` | Collects network interface statistics. |
| `user-sessions.sh` | Displays information about active user sessions. |

### Network and Service Troubleshooting

| Script | Description |
|---|---|
| `connectivity-check.sh` | Performs network connectivity checks. |
| `port-check.sh` | Tests port connectivity with a configurable timeout. |
| `ssl-check.sh` | Checks SSL/TLS certificate validity and expiration. |
| `service-health.sh` | Checks the status of system services. |

### Automation and Maintenance

| Script | Description |
|---|---|
| `backup.sh` | Creates timestamped compressed backups from configurable directories. |
| `docker-cleanup.sh` | Removes selected unused Docker resources after confirmation. |
| `log-cleanup.sh` | Automates log cleanup operations. |
| `env-check.sh` | Validates required environment configuration. |

### Quality Assurance

| Script | Description |
|---|---|
| `validate-scripts.sh` | Runs Bash syntax validation and ShellCheck checks. |

## Usage Examples

Clone the repository:

```bash
git clone https://github.com/Gabrieldelacerda/devops-scripts.git
cd devops-scripts
```

### Check Disk Usage

```bash
bash disk-check.sh
```

Use a custom utilization threshold:

```bash
THRESHOLD=85 bash disk-check.sh
```

### Check SSL Certificates

```bash
bash ssl-check.sh github.com
```

### Create a Backup

```bash
SOURCE="$HOME/projects" DEST="/tmp/test-backups" bash backup.sh
```

### Check System Services

```bash
bash service-health.sh docker
```

### Validate the Scripts

```bash
bash validate-scripts.sh
```

### Run Automated Tests

```bash
bash tests/run-tests.sh
```

Some scripts depend on system utilities, permissions, or services being available in the target Linux environment.

Review script behavior and configuration before running maintenance operations on important systems.

## Automated Testing

The repository includes automated tests for the Bash scripts.

Testing focuses on:

- Valid and invalid input handling
- Expected command output
- Command execution failures
- Boundary conditions and configurable thresholds
- Error messages and exit statuses
- Safe handling of unsuccessful operations

Tests use mocked system commands where appropriate, allowing failure scenarios to be reproduced without depending on actual infrastructure failures.

This helps validate script behavior while keeping development and testing isolated from production environments.

## Continuous Integration

GitHub Actions is used to automate repository checks.

The validation workflow helps maintain code quality by checking Bash syntax, running ShellCheck, and executing the automated test suite.

This introduces practical CI concepts such as repeatable validation, early failure detection, and consistent quality checks.

## Troubleshooting and Technical Documentation

Alongside the scripts, this repository includes technical notes covering practical infrastructure and application support scenarios.

- [Application Troubleshooting](docs/application-troubleshooting.md) — HTTP errors, Kubernetes troubleshooting concepts, and structured incident investigation.
- [Backup Verification and Recovery](docs/backup-verification.md) — Backup integrity, recovery validation, and operational considerations.

These documents complement the automation scripts and reinforce practical troubleshooting approaches.

## Engineering Practices

The scripts and tests are developed with an emphasis on:

**Reliability**

Validating inputs, checking command execution results, and handling unexpected conditions.

**Observability**

Collecting meaningful system information and producing output useful for troubleshooting.

**Automation**

Reducing repetitive operational tasks through reusable Bash utilities.

**Testing**

Using automated checks and controlled failure scenarios to verify expected behavior.

**Maintainability**

Keeping scripts focused, readable, and straightforward to extend.

## Learning Objectives

This repository supports continued development in:

- Linux system administration
- Bash scripting and automation
- Networking and infrastructure troubleshooting
- System and application monitoring
- Docker operations
- Git and version control
- Continuous integration and automated testing
- Incident investigation and operational reliability

These foundations are directly applicable to Cloud Operations, DevOps Engineering, and SRE roles.

## Roadmap

Areas for continued improvement include:

- Expanding automated test coverage
- Improving script portability and error handling
- Adding more infrastructure troubleshooting scenarios
- Exploring integrations with monitoring platforms
- Applying automation to cloud-based environments
- Developing additional CI/CD and infrastructure-as-code projects

## About

I have a professional background in corporate IT support and infrastructure, with experience in troubleshooting, incident management, networking, and supporting business-critical systems.

I am currently expanding my practical skills in Linux, automation, containers, CI/CD, and cloud technologies as part of my transition toward Cloud and DevOps engineering.

This repository documents that technical progression through hands-on projects and continuous improvement.
