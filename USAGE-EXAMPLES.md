# Practical Usage Examples

Examples of common Linux and DevOps operations using the scripts in this repository.

## Connectivity

```bash
bash connectivity-check.sh 127.0.0.1
bash port-check.sh localhost 22
```

## Service Monitoring

```bash
bash service-health.sh docker
bash process-monitor.sh 3
```

## SSL Certificate Monitoring

```bash
THRESHOLD=90 bash ssl-check.sh github.com
```

## Script Validation

```bash
bash validate-scripts.sh
```

## Exit Codes

Most health-check scripts use:

- `0` — All checks passed.
- `1` — A check failed or an error occurred.

These exit codes allow the scripts to be integrated into monitoring and automation workflows.
