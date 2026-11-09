# Review/merge-gate toggle — guided setup, no bundled script

Every AI-written PR gets a subagent self-review pass first, then is meant to wait on code review
from whoever's configured as reviewer before merge. Whether that wait is actually *enforced* is
this toggle. See `review-gate.md` (co-located with this file) for the full decision record this
guidance implements — this file is the *how*, that one is the *why*.

**No executable script ships with this skill for this.** Earlier versions bundled
`scripts/set-review-gate.sh`, which called `gh api` directly using whatever GitHub CLI
authentication was already on the machine. That's gone — this file is pure guidance: explain the
change, show its effect, get explicit confirmation, then either use a GitHub capability the
agent already has connected, or hand the user exact manual steps. Nothing here reads, stores, or
transmits a credential, and no branch-protection change happens as a side effect of normal skill
use — only when the user asks for the gate specifically.

## Before offering either direction

Confirm a real CODEOWNERS owner is in place (see `review-gate.md`'s Ownership section) and that
at least one eligible reviewer other than whoever authors this skill's PRs can actually approve
them. A solo-writer repo with the gate on blocks every PR until someone else is added or the gate
comes back off — say this plainly before turning it on, don't let the user discover it later.

## Turning it on

Explain in plain language before doing anything: *"This sets a branch protection rule on
`<branch>` requiring at least one approval before merge, dismisses stale approvals on new pushes,
and removes the admin bypass — so this includes whoever's driving me. If a CODEOWNERS file
exists, approval from the owner it names is required for the paths it covers; without one, any
approver satisfies the rule."* Wait for explicit yes before doing anything.

1. **Check for a connector that can make this change** — same detection this repo's other
   GitHub-backed skills use (`references/connector-detection.md` if packaged alongside this
   skill, or the detection method in `docs/connector-detection.md` in Athene's own repo). If a
   connected capability exists that can set branch protection, use it, show the user the exact
   settings it applied afterward, and stop here.
2. **Otherwise, hand the user these manual steps** — don't attempt the change through any local
   `gh`/API call as a fallback; this path is manual-only:
   - Go to the repo's **Settings → Branches**, and either edit the existing protection rule for
     `<branch>` or add a new one if none exists.
   - Check **Require a pull request before merging**, and under it, **Require approvals** set to
     at least 1 (if a higher number is already set, leave it — never suggest lowering an existing
     stricter requirement).
   - Check **Require review from Code Owners** — only meaningfully enforces anything if a
     CODEOWNERS file exists and covers the paths in question (see "Before offering" above).
   - Check **Dismiss stale pull request approvals when new commits are pushed**.
   - Check **Do not allow bypassing the above settings** (this is what closes the admin-bypass
     hole — without it, anyone with push access, including whoever's driving the AI agent, can
     merge around the rule).
   - Leave every other existing setting on the rule as it already is — this toggle only adds the
     four checks above, it doesn't reset or replace anything else configured there.
   - Confirm back to the user once done, and record the result in `.athene/state.md`'s Decisions
     made, same as any other decision this skill makes.

## Turning it off

Explain first: *"This removes the branch protection rule for `<branch>` entirely — including any
unrelated settings on it, not just the ones this gate added — back to discipline-only: the
convention is still followed, but nothing technically blocks a merge."* Wait for explicit yes.

1. Same connector check as above — if a connected capability can remove or edit branch
   protection, use it and confirm the result; stop here.
2. **Otherwise:** go to **Settings → Branches**, find the rule for `<branch>`, and delete it (or,
   if the user wants to keep unrelated settings on that rule, just uncheck the four boxes listed
   above instead of deleting the whole rule — offer this as the gentler option explicitly, since
   deleting the rule is what matches this skill's own historical default behavior but isn't
   always what the user actually wants).
3. Record the result in `.athene/state.md`'s Decisions made.

## Known limitation — rulesets not handled

This guidance only covers the classic branch-protection UI/API (`branches/:branch/protection`).
GitHub's newer Rulesets feature is a separate mechanism that can also require reviews on a
branch, independently of classic protection. If the target repo uses rulesets, point the user at
GitHub's branch rules UI directly rather than assuming classic protection is the only thing in
effect.

## Git host assumption

v1 default and only supported target is **GitHub** — this guidance's UI steps and terminology are
GitHub-specific, and `CODEOWNERS` is GitHub's own format. Other hosts (GitLab, Bitbucket) would
need their own equivalent guidance; that's explicitly out of v1 scope, not a silent gap.
