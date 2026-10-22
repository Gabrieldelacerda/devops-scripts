# Application and Kubernetes Troubleshooting

A practical checklist for investigating application failures in Linux and Kubernetes environments.

## HTTP 502 Bad Gateway

A gateway or reverse proxy could not obtain a valid response from an upstream service.

### Investigation

1. Check proxy logs and identify the affected upstream.
2. Verify backend availability, address, and listening port.
3. Test connectivity using `curl`.
4. Inspect application logs and recent deployments.
5. If using Kubernetes, verify pod readiness and service endpoints.
6. Fix the underlying issue and validate the HTTP response.

## Kubernetes CrashLoopBackOff

A container repeatedly terminates, and Kubernetes increases the delay between restart attempts.

### Useful Commands

- `kubectl get pods -A`
- `kubectl describe pod POD_NAME`
- `kubectl logs POD_NAME --previous`
- `kubectl get events --sort-by=.metadata.creationTimestamp`

### Common Causes

- Application startup failures
- Incorrect environment variables or configuration
- Missing dependencies
- Memory limits and OOMKilled
- Incorrect liveness probes

## Troubleshooting Workflow

1. Identify the symptoms and affected services.
2. Check logs, events, and resource usage.
3. Isolate the failing component.
4. Investigate recent changes and dependencies.
5. Apply the appropriate correction.
6. Verify recovery and document the root cause.

A failing Kubernetes backend can contribute to HTTP 502 errors, but the relationship must be confirmed through logs and connectivity checks.
