#!/usr/bin/env bash
# Packaging check for the skill set actually shipped in skills/, .agents/skills/,
# and .claude/skills/. Fails if a non-production fixture leaked into the mirrors,
# if an expected production skill is missing, or if the mirrors are stale
# relative to skills/ (scripts/mirror-skills.sh wasn't re-run after an edit).
# Run directly: scripts/check-skill-packaging.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# Update this list alongside README.md's skill table whenever a skill is
# added, removed, or renamed.
expected=(
  athene-audit
  athene-build
  athene-code-health
  athene-launch
  athene-pr-review
  athene-product-discovery
  athene-resume
)

check_dir_matches() {
  local dir="$1"
  local actual
  actual="$(find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
  local want
  want="$(printf '%s\n' "${expected[@]}" | sort)"
  if [ "$actual" != "$want" ]; then
    echo "FAIL: $dir does not contain exactly the expected seven skills."
    echo "--- expected ---"
    echo "$want"
    echo "--- actual ---"
    echo "$actual"
    exit 1
  fi
}

check_dir_matches skills

"$root/scripts/mirror-skills.sh" >/dev/null

if ! git diff --quiet -- .agents/skills .claude/skills 2>/dev/null; then
  echo "FAIL: .agents/skills/ and/or .claude/skills/ were stale — regenerating them"
  echo "from skills/ just now produced a different result than what's committed."
  echo "Review the diff with 'git diff -- .agents/skills .claude/skills', then commit it."
  exit 1
fi

check_dir_matches .agents/skills
check_dir_matches .claude/skills

echo "PASS: skills/, .agents/skills/, and .claude/skills/ all contain exactly the seven production skills, and the mirrors are current."
