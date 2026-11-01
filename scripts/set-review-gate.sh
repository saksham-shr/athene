#!/usr/bin/env bash
# Toggles the review/merge gate from a documented convention into a real technical
# block. Default is off (discipline-only) - see docs/review-gate.md. Requires jq.
#
# Usage: scripts/set-review-gate.sh <owner/repo> <branch> <on|off>
set -euo pipefail

repo="${1:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"
branch="${2:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"
mode="${3:?usage: set-review-gate.sh <owner/repo> <branch> <on|off>}"

# Encode the branch name so a name containing #, %, or / can't retarget the
# request at a different endpoint or a different branch.
encoded_branch="$(jq -rn --arg b "$branch" '$b|@uri')"
protection_path="repos/$repo/branches/$encoded_branch/protection"

if [ "$mode" = "on" ]; then
  # Fetch first so turning the gate on doesn't clobber required_status_checks or
  # push restrictions a repo already has for unrelated reasons.
  if existing="$(gh api "$protection_path" 2>/dev/null)"; then
    status_checks="$(printf '%s' "$existing" | jq -c '.required_status_checks // null')"
    restrictions="$(printf '%s' "$existing" | jq -c '.restrictions // null')"
  else
    status_checks=null
    restrictions=null
  fi

  jq -n \
    --argjson status_checks "$status_checks" \
    --argjson restrictions "$restrictions" \
    '{
      required_status_checks: $status_checks,
      enforce_admins: true,
      required_pull_request_reviews: {
        required_approving_review_count: 1,
        require_code_owner_reviews: true,
        dismiss_stale_reviews: true
      },
      restrictions: $restrictions
    }' | gh api --method PUT "$protection_path" --input -

  echo "Review gate ON for $repo@$branch: unreviewed or non-owner-approved PRs cannot merge," \
       "stale approvals are dismissed on new pushes, admin bypass disabled." \
       "Existing status checks/restrictions preserved."

elif [ "$mode" = "off" ]; then
  if gh api "$protection_path" >/dev/null 2>&1; then
    gh api --method DELETE "$protection_path"
    echo "Review gate OFF for $repo@$branch: back to discipline-only convention, no technical block."
  else
    echo "Review gate already off for $repo@$branch (no protection rule found)."
  fi

else
  echo "mode must be 'on' or 'off', got: $mode" >&2
  exit 1
fi
