
# Network Diagnostics

Practical examples of using the repository's scripts to investigate connectivity, DNS, TLS, and HTTP issues.

## 1. Check Network Connectivity

```bash
bash connectivity-check.sh github.com
```

Send multiple ICMP packets:

```bash
PING_COUNT=3 PING_TIMEOUT=5 bash connectivity-check.sh github.com
```

A failed ping does not always mean the service is unavailable. ICMP traffic may be blocked.

## 2. Check DNS Resolution

```bash
bash dns-check.sh github.com
```

Query a specific DNS resolver:

```bash
DNS_SERVER=1.1.1.1 bash dns-check.sh github.com
```

Check IPv6 records:

```bash
DNS_TYPE=AAAA bash dns-check.sh github.com
```

Comparing DNS responses can help identify resolver or configuration issues.

## 3. Check TCP Connectivity

```bash
bash port-check.sh github.com 443
```

A reachable TCP port does not guarantee that the application is healthy.

## 4. Check TLS Certificates

```bash
bash ssl-check.sh github.com
```

Certificate validation helps investigate HTTPS connectivity and expiration issues.

## 5. Check HTTP Endpoints

```bash
bash http-health-check.sh https://github.com
```

Use a HEAD request:

```bash
HTTP_METHOD=HEAD bash http-health-check.sh https://github.com
```

Follow redirects:

```bash
HTTP_FOLLOW_REDIRECTS=1 bash http-health-check.sh https://github.com
```

The script reports unexpected HTTP status codes and common curl failures, including DNS resolution, connection, timeout, and TLS errors.

## Troubleshooting Workflow

A practical investigation can follow this sequence:

1. DNS resolution
2. Network connectivity and routing
3. TCP port connectivity
4. TLS certificate validation
5. HTTP response
6. Application logs and backend services

Each check investigates a different layer. Combining their results helps narrow down the cause of a failure before escalating an incident.
