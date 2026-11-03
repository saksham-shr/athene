#!/usr/bin/env bash
# Self-check for debt-ledger.sh: plants one marker with an upgrade trigger and
# one without, in a throwaway git repo, and asserts the ledger counts and
# flags them correctly. Run directly: scripts/debt-ledger-test.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cd "$tmp"
git init -q
cat > sample.sh <<'EOF'
# athene: global lock, per-account locks if throughput matters
echo "has trigger"
# athene: naive O(n^2) scan
echo "no trigger"
EOF
git add sample.sh

out="$("$root/scripts/debt-ledger.sh")"

echo "$out" | grep -q "2 marker(s), 1 flagged as rot risk." || {
  echo "FAIL: summary line wrong. Got:"
  echo "$out"
  exit 1
}
echo "$out" | grep -q "global lock, per-account locks if throughput matters$" || {
  echo "FAIL: triggered marker missing or mis-flagged"
  exit 1
}
echo "$out" | grep -q "naive O(n^2) scan  \[ROT RISK: no upgrade trigger named\]" || {
  echo "FAIL: rot-risk marker not flagged"
  exit 1
}

echo "PASS: debt-ledger.sh"
