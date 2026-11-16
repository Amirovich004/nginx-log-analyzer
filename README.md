# nginx-log-analyzer

Small bash script that reads an nginx access log and prints a summary: total requests, unique
clients, error rate, status code breakdown, busiest clients and the busiest minute.

![ci](https://github.com/Amirovich004/nginx-log-analyzer/actions/workflows/ci.yml/badge.svg)

## usage

```bash
./bin/log-analyzer /var/log/nginx/access.log
```

```
File: /var/log/nginx/access.log
Requests: 20
Unique clients: 8
Error rate: 30.0% (6 of 20)

Status classes:
  2xx: 12
  3xx: 2
  4xx: 3
  5xx: 3

Top clients:
  10.0.0.1: 4
  10.0.0.2: 3
  192.168.0.7: 3
  203.0.113.9: 3
  10.0.0.3: 2
  10.0.0.5: 2
  198.51.100.23: 2
  10.0.0.4: 1

Busiest minute: 2024-10-10T13:55 (11 requests)
```

Options:

- `--top N` how many clients to list (default 10)
- `--format text|json` output format (default text)
- `-h`, `--help` show usage

Exit codes: `0` ok, `1` file missing or no valid lines, `2` bad arguments.

## json

Useful if you want to feed the numbers into something else:

```bash
./bin/log-analyzer access.log --top 2 --format json
```

```json
{
  "file": "access.log",
  "total_requests": 20,
  "unique_clients": 8,
  "error_rate_percent": 30.0,
  "status_classes": {"2xx": 12, "3xx": 2, "4xx": 3, "5xx": 3},
  "top_clients": [{"ip": "10.0.0.1", "requests": 4}, {"ip": "10.0.0.2", "requests": 3}],
  "busiest_minute": {"minute": "2024-10-10T13:55", "requests": 11}
}
```

## docker

```bash
docker build -t nginx-log-analyzer .
docker run --rm -v "$PWD/tests/fixtures:/logs:ro" nginx-log-analyzer /logs/sample.log
```

The image is alpine with bash and gawk installed. Logs are mounted read only.

## tests

```bash
bash tests/run-tests.sh
```

Plain bash assertions on a small fixture, no test framework. Runs in CI together with
shellcheck and a docker smoke test.

## notes

- only the nginx combined format is handled
- gzipped logs and log rotation are not handled
- the file is read in one awk pass, so split very large logs first
- lines that don't parse are skipped and counted in a warning on stderr
