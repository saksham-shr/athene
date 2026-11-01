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

err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

# Prints the existing protection JSON and returns 0 if a rule exists; returns 1
# only when GitHub confirms there is none (404). Any other failure (auth,
# rate-limit, network) stops the script instead of being treated as "no rule" -
# that distinction matters on both the enable path (would wipe real settings)
# and the disable path (would falsely report the gate as already off).
fetch_existing_protection() {
  local out
  if out="$(gh api "$protection_path" 2>"$err_file")"; then
    printf '%s' "$out"
    return 0
  fi
  if grep -q 'HTTP 404' "$err_file"; then
    return 1
  fi
  echo "Could not read branch protection for $repo@$branch: $(cat "$err_file")" >&2
  exit 1
}

if [ "$mode" = "on" ]; then
  if existing="$(fetch_existing_protection)"; then
    :
  else
    existing='null'
  fi

  if ! gh api "repos/$repo/contents/.github/CODEOWNERS" >/dev/null 2>&1 \
     && ! gh api "repos/$repo/contents/CODEOWNERS" >/dev/null 2>&1 \
     && ! gh api "repos/$repo/contents/docs/CODEOWNERS" >/dev/null 2>&1; then
    echo "Warning: no CODEOWNERS file found at .github/CODEOWNERS, CODEOWNERS, or" >&2
    echo "docs/CODEOWNERS. require_code_owner_reviews only applies to paths matched in" >&2
    echo "CODEOWNERS - without one, any writer's approval satisfies this rule." >&2
  fi

  # GitHub's GET and PUT shapes for branch protection disagree: GET returns
  # nested {enabled: bool} objects and richer check/restriction objects; PUT
  # wants flat booleans and {context, app_id}/login/slug strings. Convert
  # rather than round-trip the GET shape straight into the PUT body.
  payload="$(jq -n --argjson existing "$existing" '
    ($existing // {}) as $e
    | {
        required_status_checks: (
          if ($e.required_status_checks // null) == null then null
          else {
            strict: ($e.required_status_checks.strict // false),
            checks: [($e.required_status_checks.checks // [])[] |
              if .app_id == null then {context: .context}
              else {context: .context, app_id: .app_id} end]
          }
          end
        ),
        enforce_admins: true,
        required_pull_request_reviews: {
          required_approving_review_count:
            ([1, ($e.required_pull_request_reviews.required_approving_review_count // 0)] | max),
          require_code_owner_reviews: true,
          dismiss_stale_reviews: true
        },
        restrictions: (
          if ($e.restrictions // null) == null then null
          else {
            users: [($e.restrictions.users // [])[] | .login],
            teams: [($e.restrictions.teams // [])[] | .slug],
            apps: [($e.restrictions.apps // [])[] | .slug]
          }
          end
        ),
        required_linear_history: ($e.required_linear_history.enabled // false),
        allow_force_pushes: ($e.allow_force_pushes.enabled // false),
        allow_deletions: ($e.allow_deletions.enabled // false),
        block_creations: ($e.block_creations.enabled // false),
        required_conversation_resolution: ($e.required_conversation_resolution.enabled // false),
        lock_branch: ($e.lock_branch.enabled // false),
        allow_fork_syncing: ($e.allow_fork_syncing.enabled // false)
      }
  ')"

  printf '%s' "$payload" | gh api --method PUT "$protection_path" --input -

  echo "Review gate ON for $repo@$branch: unreviewed PRs cannot merge; owner-specific" \
       "approval applies only to paths covered by a CODEOWNERS file, if one exists." \
       "Stale approvals are dismissed on new pushes, admin bypass disabled." \
       "Existing protection settings preserved where GitHub's API allows reading them back."

elif [ "$mode" = "off" ]; then
  if fetch_existing_protection >/dev/null; then
    gh api --method DELETE "$protection_path"
    echo "Review gate OFF for $repo@$branch: back to discipline-only convention, no technical block."
  else
    echo "Review gate already off for $repo@$branch (no protection rule found)."
  fi

else
  echo "mode must be 'on' or 'off', got: $mode" >&2
  exit 1
fi
