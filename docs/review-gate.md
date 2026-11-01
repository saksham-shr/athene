# Review/merge-gate toggle

Every AI-written PR gets a subagent self-review pass first (see the code-review convention
elsewhere in this repo's own build history), then is meant to wait on code review from whoever's
configured as reviewer before merge. Whether that wait is actually *enforced* is this toggle.

## Default: off

Discipline-only. The agent follows the convention — wait for review, don't self-merge — but
nothing technical stops it from merging anyway. Right default for a non-technical user: no branch
protection to misconfigure, no "why is my push rejected" surprise.

## On: a real technical gate

For experienced users who want this enforced, not just followed. Flipping it on must produce an
actual GitHub branch-protection rule — a documented convention that can be skipped isn't a gate.

`scripts/set-review-gate.sh <owner/repo> <branch> on` sets:
- `required_pull_request_reviews`: at least one approval required before merge — more if the
  branch already required more (never silently lowers an existing stricter count). Owner-specific
  approval is requested via `require_code_owner_reviews: true`, but **this only applies to paths a
  `CODEOWNERS` file actually matches** (see Ownership below) — without one, any writer's approval
  satisfies the rule regardless of this setting. The script warns on stderr if it can't find a
  `CODEOWNERS` file before enabling, rather than silently granting a guarantee it can't back. Stale
  approvals are dismissed on new pushes (`dismiss_stale_reviews: true` — without it, pushing new
  commits after approval and merging without a fresh review is a real bypass). Preserves an
  existing `dismissal_restrictions` setting (who can dismiss a required review) rather than
  dropping it — without that, enabling the gate would let anyone with push access dismiss a
  review that was supposed to be restricted.
- `enforce_admins: true`: closes the default admin-bypass hole. Branch protection without this
  is cosmetic — admins (including whoever's driving the AI agent) can merge around it by default.
- Preserves the branch's existing protection settings where GitHub's API allows reading them back
  and converting them to the shape the update endpoint expects — `required_status_checks`,
  `restrictions`, and the flat booleans (`required_linear_history`, `allow_force_pushes`,
  `allow_deletions`, `block_creations`, `required_conversation_resolution`, `lock_branch`,
  `allow_fork_syncing`). GitHub's GET and PUT shapes for these disagree (GET returns richer
  objects than PUT accepts), so the script converts rather than round-trips the raw GET response.
- Distinguishes "branch genuinely has no protection yet" (HTTP 404) from a transient API/auth/
  network failure while checking existing settings — a failure of the latter kind stops the
  script instead of being silently treated as "nothing to preserve." The same distinction applies
  on `off`: a 404 on the protection endpoint also happens for a nonexistent branch or a repo the
  token can't access, so the script confirms the branch itself resolves before reporting "already
  off" — it won't claim the gate is off just because it couldn't read the branch at all.

**Known limitation — rulesets not handled.** This script only manages the classic branch-
protection API (`branches/:branch/protection`). GitHub's newer Rulesets feature is a separate
mechanism that can also require reviews on a branch, independently of classic protection — a
repo using rulesets could still require review after this script reports the gate "off" (classic
protection genuinely removed, but a ruleset still enforcing). Checking and reporting on rulesets
is out of scope here; if a repo uses them, verify review enforcement directly in GitHub's branch
rules UI/API, not through this script's output alone.

`scripts/set-review-gate.sh <owner/repo> <branch> off` removes the protection rule entirely, back
to discipline-only — same existence-check logic: a 404 means "already off" and exits cleanly,
anything else (including a failed DELETE) stops the script rather than claiming success. Known
limitation: `on` preserves whatever unrelated protection existed *at the moment it's turned on*,
but `off` removes the whole rule rather than restoring exactly what was there before `on` was ever
run — there's no snapshot of that earlier state. If a branch had unrelated protection before this
script touched it, turning the gate off removes that too, not just this gate's additions.

Requires `jq` (used to URL-encode the branch name and convert the protection payload).

## Ownership

`skills/athene-audit/templates/CODEOWNERS` is the path-to-owner map template: who reviews each
path. Separately, by default:
- **Who merges:** whoever the repo's branch protection allows — same person/bot driving Athene,
  unless the gate above is on and a different reviewer is required.
- **Who creates issues/PRs by default:** the AI agent, user-overridable — if the user wants to
  create issues/PRs themselves instead, that's a one-line override, not a different code path.

## Git host assumption

v1 default and only supported target is **GitHub** — `scripts/set-review-gate.sh` calls `gh api`
directly, and `CODEOWNERS` is GitHub's own format. Other hosts (GitLab, Bitbucket) would need
their own equivalent script and ownership-file format; that's explicitly out of v1 scope, not a
silent gap.

## Wired into Audit

Athene: Audit offers this toggle at the end of its run (copies the script, explains it) but
never runs it itself — turning it on is always the user's call. Still not wired into the eventual
`athene` build skill (doesn't exist in this repo yet) — that's the remaining follow-up.
