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

## Either direction, always

- **Confirm the actual branch-pattern scope before changing anything.** A classic protection rule
  can be set on a pattern (`release/*`), not just one literal branch name — editing or deleting
  "the rule for `<branch>`" can silently change protection for every other branch that pattern
  also matches. Show the user the rule's actual pattern and get confirmation for that real scope,
  not just the one branch name they asked about.
- **Check for a connector that can make this change** — same detection this repo's other
  GitHub-backed skills use (`references/connector-detection.md` if packaged alongside this
  skill, or the detection method in `docs/connector-detection.md` in Athene's own repo — use its
  targeted, grep-style check, never a full read of a config file that can hold other servers'
  secrets). If a connected capability exists that can read and set branch protection, use it,
  show the user the exact settings it applied afterward, and stop here.
- **Act on whichever direction the user actually asked for** — on or off, never assume "offering
  the gate" means only turning it on; a user asking to turn an existing gate off needs this
  guidance too.

## Turning it on

**Prerequisite, before explaining the change:** confirm a real CODEOWNERS owner is in place (see
`review-gate.md`'s Ownership section) who is **not** the only person authoring this skill's
PRs — a second approver who isn't an eligible code owner for the paths in question doesn't
satisfy `Require review from Code Owners`, and the author still can't approve their own PR. A
solo-writer repo, or one where the only CODEOWNERS entry is the PR author, blocks every PR the
moment this gate is on. Say this plainly before turning it on, don't let the user discover it
later. This prerequisite applies to turning the gate on only — don't let it block turning an
already-on gate back off (see below).

Explain in plain language before doing anything: *"This sets a branch protection rule on
`<branch>` requiring at least one approval before merge, dismisses stale approvals on new pushes,
and removes the admin bypass — so this includes whoever's driving me. If a CODEOWNERS file
exists, approval from the owner it names is required for the paths it covers; without one, any
approver satisfies the rule."* Wait for explicit yes before doing anything.

No connector available — hand the user these manual steps (don't attempt the change through any
local `gh`/API call as a fallback; this path is manual-only):

- Go to the repo's **Settings → Branches**. If a rule for `<branch>` already exists, open it for
  editing and note which of the settings below are already checked, before changing anything —
  that list is what "Turning it off" below needs to restore correctly, not guess at. If none
  exists, click **Add branch protection rule** and enter `<branch>` (or its exact existing
  pattern, confirmed above) into **Branch name pattern**.
- Check **Require a pull request before merging**, and under it, **Require approvals** set to
  at least 1 (if a higher number is already set, leave it — never suggest lowering an existing
  stricter requirement).
- Check **Require review from Code Owners** — only meaningfully enforces anything if a
  CODEOWNERS file exists, covers the paths in question, and names an owner other than the PR
  author (see the prerequisite above).
- Check **Dismiss stale pull request approvals when new commits are pushed**.
- Check **Do not allow bypassing the above settings** (this closes the *admin*-bypass hole —
  without it, anyone with push access, including whoever's driving the AI agent, can merge
  around the rule). This does **not** cover a separate setting, **Allow specified actors to
  bypass required pull requests** — if that list already names any user, team, or app, tell the
  user explicitly that whoever's listed there can still bypass this gate regardless of the box
  above, and ask whether that allowance should be removed too; don't report the gate as fully
  enforced without disclosing it.
- Leave every other existing setting on the rule as it already is — this toggle only adds the
  checks above, it doesn't reset or replace anything else configured there.
- Click **Create** (new rule) or **Save changes** (existing rule) — nothing above takes effect
  until this is clicked.
- Confirm back to the user once done, and record the result in `.athene/state.md`'s Decisions
  made, same as any other decision this skill makes.

## Turning it off

Explain first: *"This removes `<branch>`'s branch protection rule's PR-review requirements. If
any of the settings below predate this gate, I'll leave those as they already were rather than
removing protection you had before I touched anything — otherwise this removes the rule
entirely, back to discipline-only: the convention is still followed, but nothing technically
blocks a merge."* Wait for explicit yes.

No connector available:

- If you (or the user) noted which settings were already checked before this gate was turned on
  (see "Turning it on" above): uncheck only the ones this gate added that weren't already
  checked, leave the rest exactly as they were, then **Save changes**. This is always the safer
  choice when that record exists.
- If there's no such record — the gate predates this guidance, or the rule's prior state was
  never captured — ask the user whether to delete the whole rule (matches this skill's own
  historical default, simplest, but removes anything else on it too) or uncheck just the four
  boxes this gate's "on" procedure adds, explaining that the second option risks leaving an
  unrelated setting in whatever state it happened to be found in. Don't silently pick one.
- Record the result in `.athene/state.md`'s Decisions made.

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
