#!/usr/bin/env bash
# Toggles the review/merge gate from a documented convention into a real technical
# block. Default is off (discipline-only) - see docs/review-gate.md.
#
# Usage: scripts/set-review-gate.sh <owner/repo> <branch> <on|off>
set -euo pipefail

repo="${1:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"
branch="${2:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"
mode="${3:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"

if [ "$mode" = "on" ]; then
  # required_pull_request_reviews blocks merge without an approval.
  # enforce_admins:true closes the default admin-bypass hole - without it,
  # this "gate" isn't a real block, just a suggestion admins can skip.
  gh api --method PUT "repos/$repo/branches/$branch/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF
  echo "Review gate ON for $repo@$branch: unreviewed PRs cannot merge, admin bypass disabled."
elif [ "$mode" = "off" ]; then
  gh api --method DELETE "repos/$repo/branches/$branch/protection" || true
  echo "Review gate OFF for $repo@$branch: back to discipline-only convention, no technical block."
else
  echo "mode must be 'on' or 'off', got: $mode" >&2
  exit 1
fi
