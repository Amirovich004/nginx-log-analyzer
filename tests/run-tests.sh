#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/bin/log-analyzer"
FIXTURE="$ROOT/tests/fixtures/sample.log"

pass=0
fail=0

ok() { pass=$((pass + 1)); printf 'ok   %s\n' "$1"; }
not_ok() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1"; }

expect_contains() {
  local name="$1" needle="$2" haystack="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    ok "$name"
  else
    not_ok "$name -- expected to contain: $needle"
  fi
}

expect_missing() {
  local name="$1" needle="$2" haystack="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    not_ok "$name -- expected NOT to contain: $needle"
  else
    ok "$name"
  fi
}

expect_exit() {
  local name="$1" expected="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local actual=$?
  if [ "$actual" -eq "$expected" ]; then
    ok "$name"
  else
    not_ok "$name -- expected exit $expected, got $actual"
  fi
}

if [ ! -x "$SCRIPT" ]; then
  not_ok "script is present and executable"
  printf '\n%d passed, %d failed\n' "$pass" "$fail"
  exit 1
fi

ok "script is present and executable"

text="$("$SCRIPT" "$FIXTURE")"
expect_contains "total requests" "Requests: 20" "$text"
expect_contains "unique clients" "Unique clients: 8" "$text"
expect_contains "error rate" "Error rate: 30.0% (6 of 20)" "$text"
expect_contains "2xx count" "2xx: 12" "$text"
expect_contains "3xx count" "3xx: 2" "$text"
expect_contains "4xx count" "4xx: 3" "$text"
expect_contains "5xx count" "5xx: 3" "$text"
expect_contains "top client" "10.0.0.1: 4" "$text"
expect_contains "busiest minute" "2024-10-10T13:55 (11 requests)" "$text"

json="$("$SCRIPT" "$FIXTURE" --format json)"
expect_contains "json total" '"total_requests": 20' "$json"
expect_contains "json unique" '"unique_clients": 8' "$json"
expect_contains "json error rate" '"error_rate_percent": 30.0' "$json"

top2="$("$SCRIPT" "$FIXTURE" --top 2)"
expect_contains "top 2 keeps first client" "10.0.0.1: 4" "$top2"
expect_missing "top 2 drops the rest" "203.0.113.9" "$top2"

expect_exit "missing file exits 1" 1 "$SCRIPT" "$ROOT/tests/fixtures/missing.log"
expect_exit "no arguments exits 2" 2 "$SCRIPT"
expect_exit "unknown format exits 2" 2 "$SCRIPT" "$FIXTURE" --format xml
expect_exit "non numeric top exits 2" 2 "$SCRIPT" "$FIXTURE" --top abc
expect_exit "empty file exits 1" 1 "$SCRIPT" "$ROOT/tests/fixtures/empty.log"
expect_exit "help exits 0" 0 "$SCRIPT" --help

py=""
for candidate in python3 python; do
  # The Windows Store python3 alias exists but is not a working interpreter.
  if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import json' >/dev/null 2>&1; then
    py="$candidate"
    break
  fi
done

if [ -n "$py" ]; then
  if printf '%s' "$json" | "$py" -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
    ok "json output is valid"
  else
    not_ok "json output is valid"
  fi
else
  printf 'skip json syntax validation (no working python on this machine)\n'
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
