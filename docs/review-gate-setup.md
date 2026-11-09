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
  skill, or the detection method in `docs/connector-detection.md` in Athene's own repo). If a
  connected capability exists that can read and set branch protection *for the confirmed scope*
  (a wildcard pattern like `release/*` needs a connector that can actually address a pattern, not
  just a single literal branch), use it instead of the manual steps below *for the actual API
  calls only* — every other step (the scope confirmation above, the direction-specific
  prerequisite and explanation, what gets disclosed, and recording the result) still applies
  exactly the same way; a connector changes how the setting gets written, not whether this
  guidance's safeguards run. If no available connector can address the confirmed scope, use the
  manual steps instead, even if one exists for literal-branch rules.
- **Act on whichever direction the user actually asked for** — on or off, never assume "offering
  the gate" means only turning it on; a user asking to turn an existing gate off needs this
  guidance too.

## Turning it on

**Prerequisite, before explaining the change:** GitHub never lets a PR's own author approve it,
regardless of any setting here — so even the core setting (no CODEOWNERS needed at all) blocks
every PR in a repo with no eligible reviewer besides whoever authors this skill's PRs, unless an
applicable bypass allowance covers them. Check what `Require approvals` will actually be set to —
if a rule already exists, that's `max(1, its current count)` (the manual steps below always set
at least 1, even starting from an existing count of 0 — GitHub allows 0); for a brand new rule,
it's 1. Confirm *at least that many* other eligible reviewers exist before turning this on at
all — one eligible reviewer isn't enough if the resulting count is 2 or more. Separately,
**Require review from Code Owners** specifically needs a real CODEOWNERS owner (see
`review-gate.md`'s Ownership section) who is eligible *for the specific paths this skill's PRs
actually touch, by whoever actually authors them* — a repo-wide CODEOWNERS entry for a different
path doesn't help (e.g. Bob owning `/docs` doesn't satisfy a PR from Alice, the sole owner of
`/src`, touching only `/src`). Say all of this plainly before turning anything on, don't let the
user discover any of it later; if there's no eligible CODEOWNERS owner for the paths actually in
play but enough general eligible reviewers do exist, turn on everything else and skip just that
one box (and the matching manual step below), or wait until an owner is added. This prerequisite
applies to turning the gate on only — don't let it block turning an already-on gate back off (see
below).

Explain in plain language before doing anything: *"This sets a branch protection rule on
`<branch>` requiring at least one approval before merge, dismisses stale approvals on new pushes,
and removes the admin bypass — so this includes whoever's driving me. PRs can't be approved by
their own author, so this needs at least one other eligible reviewer."* Then, depending on
whether the prerequisite above found an eligible CODEOWNERS owner: *"A CODEOWNERS file exists and
names an eligible owner, so approval from that owner is required for the paths it covers"* (box
will be checked), or *"this rule won't require Code Owners approval specifically"* — naming the
real reason, either no CODEOWNERS file exists or none of its owners are eligible — *"any eligible
reviewer's approval satisfies it instead"* (box will be left unchecked). Wait for explicit yes
before doing anything.

No suitable connector available — hand the user these manual steps (don't attempt the change through any
local `gh`/API call as a fallback; this path is manual-only):

- Go to the repo's **Settings → Branches**. Record whether a rule for `<branch>` already
  exists — that single fact is what "Turning it off" below needs most. If one already exists,
  open it for editing and also note which of the settings below are already checked, before
  changing anything. If none exists, click **Add branch protection rule** and enter `<branch>`
  (or its exact existing pattern, confirmed above) into **Branch name pattern**.
- Check **Require a pull request before merging**, and under it, **Require approvals** set to
  at least 1 (if a higher number is already set, leave it — never suggest lowering an existing
  stricter requirement).
- Check **Require review from Code Owners** *only if* the prerequisite above found an eligible
  owner — otherwise leave it unchecked, matching what you already told the user. Checking it
  despite no eligible owner existing would block every PR, contradicting the "any eligible
  reviewer satisfies it" explanation already given.
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

No suitable connector available:

- **If "Turning it on" recorded that the rule itself didn't exist before this gate created it:**
  delete the whole rule. A classic protection rule carries its own defaults beyond this gate's
  four checkboxes (e.g. blocking force-pushes and branch deletion) — unchecking just those four
  and leaving the rule in place doesn't actually return the branch to its pre-gate state;
  deleting the rule this gate created is what does.
- **If the rule existed before this gate touched it, and its prior checkbox state was
  recorded:** uncheck only the ones this gate added that weren't already checked, leave the rest
  (including any non-gate defaults already on the rule) exactly as they were, then **Save
  changes**.
- **If neither is known** — the gate predates this guidance, or the rule's prior state was never
  captured: ask the user whether to delete the whole rule (simplest, but removes anything else on
  it too) or uncheck just the four boxes this gate's "on" procedure adds, explaining that the
  second option risks leaving an unrelated setting — including the rule's own non-gate
  defaults — in whatever state they happened to be in. Don't silently pick one.
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
