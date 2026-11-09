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
At minimum: at least one approval required before merge (owner-specific via CODEOWNERS where one
exists and covers the paths in question), stale approvals dismissed on new pushes, and the
admin-bypass hole closed. **How this actually gets set is `review-gate-setup.md` (co-located with
this file)** — a guided, confirm-before-acting flow using a connected GitHub capability if one
exists, manual GitHub UI steps otherwise. No bundled script calls `gh api` on the user's behalf
any more; see that file for why and for the exact steps.

**Known limitation — rulesets not handled.** The guidance only covers the classic branch-
protection UI/API (`branches/:branch/protection`). GitHub's newer Rulesets feature is a separate
mechanism that can also require reviews on a branch, independently of classic protection — a repo
using rulesets could still require review after the gate is reported "off" (classic protection
genuinely removed, but a ruleset still enforcing). If a repo uses them, verify review enforcement
directly in GitHub's branch rules UI, not from this gate's state alone.

Turning it off removes the protection rule entirely, back to discipline-only — see
`review-gate-setup.md` for the gentler option (unchecking just the four settings this gate adds,
instead of deleting the whole rule) when the branch had other, unrelated protection worth keeping.

## Ownership

`skills/athene-audit/templates/CODEOWNERS` is the path-to-owner map template: who reviews each
path. Separately, by default:
- **Who merges:** whoever the repo's branch protection allows — same person/bot driving Athene,
  unless the gate above is on and a different reviewer is required.
- **Who creates issues/PRs by default:** the AI agent, user-overridable — if the user wants to
  create issues/PRs themselves instead, that's a one-line override, not a different code path.

## Git host assumption

v1 default and only supported target is **GitHub** — `review-gate-setup.md`'s UI steps and
`CODEOWNERS` are both GitHub-specific. Other hosts (GitLab, Bitbucket) would need their own
equivalent guidance and ownership-file format; that's explicitly out of v1 scope, not a silent
gap.

## Wired into Audit

Athene: Audit offers this toggle at the end of its run (explains what it does, per
`review-gate-setup.md`) but never acts on it itself — turning it on is always the user's call.
Also wired into `athene-build`, the build skill — same offer, made during Design instead of at
adoption time.
