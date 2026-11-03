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
/* athene: naive cache, */ int x;
EOF
git add sample.sh

# Untracked file - never git add'ed - must still be found (--untracked).
cat > untracked.sh <<'EOF'
# athene: skip validation here, add it before shipping
EOF

out="$("$root/scripts/debt-ledger.sh")"

echo "$out" | grep -q "4 marker(s), 2 flagged as rot risk." || {
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
echo "$out" | grep -q "naive cache,  \[ROT RISK: no upgrade trigger named\]" || {
  echo "FAIL: block-comment marker's trailing code wasn't stripped before the upgrade-path check"
  exit 1
}
echo "$out" | grep -q "skip validation here, add it before shipping$" || {
  echo "FAIL: untracked file's marker not found - --untracked may be missing"
  exit 1
}

# submodule.recurse=true makes plain `git grep --untracked` fail outright
# (conflicts with implied --recurse-submodules) - must still find markers.
git config submodule.recurse true
out2="$("$root/scripts/debt-ledger.sh")"
echo "$out2" | grep -q "4 marker(s), 2 flagged as rot risk." || {
  echo "FAIL: submodule.recurse=true broke the ledger (--no-recurse-submodules missing?). Got:"
  echo "$out2"
  exit 1
}

echo "PASS: debt-ledger.sh"
