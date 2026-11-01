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
- `required_pull_request_reviews`: at least one approval required before merge.
- `enforce_admins: true`: closes the default admin-bypass hole. Branch protection without this
  is cosmetic — admins (including whoever's driving the AI agent) can merge around it by default.

`scripts/set-review-gate.sh <owner/repo> <branch> off` removes the protection rule, back to
discipline-only.

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

## Not yet wired into Audit

Same note as the risk-tier mapping table: Athene: Audit's current scope stays limited to the
fixed baseline. Wiring this toggle and the CODEOWNERS template into Audit's actual generation
flow is a follow-up, not part of this doc.
