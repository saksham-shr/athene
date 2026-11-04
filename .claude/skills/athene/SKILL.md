---
name: athene
description: Establish a repo's operating model, then build - lifecycle, ownership, CI/CD, stack decisions, governance. Use when starting a new build. Skip if no Athene footprint exists yet (hands off to Athene: Audit) or for a one-off coding task with no process implications.
---

# Athene (repo + build + architecture)

Establishes the repo's operating model before any code is written, then builds. Distinct from
Athene: Audit, which retrofits process onto a repo that already exists — this skill is for a new
build, not a retrofit. If the repo already has real work in it but no Athene footprint, that's
Audit's job, not this one.

GitHub is the v1-assumed git host — CODEOWNERS, PR/issue templates, and branch protection below
all assume it. Other hosts are a later extension, not v1 scope.

## Check for existing Athene footprint first

On start, scan the target repo for `.athene/state.md`.

- **Not found:** don't proceed as if this were a clean greenfield repo just because this skill
  was invoked directly — read and follow the Athene: Audit skill file first. This is how this
  skill and Audit disambiguate without relying on how the user phrased the request.
- **Found:** read all four sections before doing anything else — don't just confirm the file
  exists and barge into the lifecycle below. Check `Active skill`:
  - **`athene`:** continue below, picking up at whatever `Current phase` names. If `Current
    phase` is `handoff` (the reserved value a handing-off skill like Athene: Product Discovery
    leaves — see `docs/state-schema.md`), that isn't one of this skill's own lifecycle stage
    names: start at **Intake**, this lifecycle's first stage, rather than treating `handoff` as
    an unrecognized phase.
  - **Anything else:** this skill doesn't own the repo right now. Read and follow whichever
    skill file `Active skill` names instead — stop and say so if that file isn't packaged where
    this skill is installed. Don't start deciding work or touching state another skill owns.

## Lifecycle

Design stages only where each has an owner and an exit condition — adapted from the handbook
model this project's planning already settled on:

1. **Intake** — forms request a duplicate search, minimal reproduction, environment/version,
   expected/observed behavior, impact, alternatives. Route support questions elsewhere; publish
   a private security path.
2. **Triage** — label area, type, platform, severity; assign an owner; explicit states (`needs
   reproduction`, `needs design`, `actionable`, `won't fix`). Only a reviewer makes work
   actionable.
3. **Design** — require an issue/RFC for public API, behavior, architecture, format,
   performance-contract, or security changes. Capture problem, non-goals, alternatives,
   compatibility/migration, tests, rollback. This is where stack decisions, connector setup,
   evidence-backed architecture, and the engineering quality bar all apply — see the two
   dedicated sections below.
4. **Implementation** — supported toolchains, reproducible bootstrap/lint/targeted-test/docs-
   preview/debugging paths. Focused diffs, risk-proportionate tests, docs/release impact
   assessed.
5. **PR intake** — drafts until ready. Non-trivial external work needs an accepted issue or a
   named sponsor, a concise human-written summary, compatibility disclosure, performance
   evidence where relevant. Run CLA/license/security checks early.
6. **Review** — route by path ownership plus fallback (see Governance artifacts below for the
   ownership map and the review/merge gate). Evaluate correctness, tests, operations, docs,
   compatibility, performance, security, maintainability. Re-review when the approved surface
   materially changes. Self-review with a subagent pass before waiting on the configured reviewer
   — queue discipline that holds whether or not the technical gate is switched on.
7. **CI and merge** — cheap deterministic checks first; platform/integration/performance
   coverage chosen from paths and risk; PR gates separate from scheduled/nightly/release
   qualification. Protect default branches with verified requirements, approvals, a merge queue
   or equivalent. Document retry/flaky-test handling.
8. **Release and post-merge** — branch/cadence policy, release-note ownership, artifact
   verification, smoke tests, rollback/revert procedure, patch policy. Monitor the default
   branch, feed regressions into tests and triage.

## Make ownership executable

Keep a versioned path-to-owner map for review routing and merge authorization, with backups and
escalation. Use the same change metadata to drive relevant CI and release-note categories, but
never let a label change grant privileges or suppress a required check.

## CI/CD architecture

- **Pre-merge:** format/lint, static/type checks, unit and focused integration tests,
  security/license/secret scans, docs build, compatibility/API checks where relevant.
- **Change-aware expansion:** map changed paths to platform, accelerator, distributed, packaging,
  or benchmark jobs. Conservative defaults where mapping is unreliable.
- **Post-merge/scheduled:** broad matrices, slow tests, upgrade/cross-version checks, performance
  regression detection, dependency refresh, artifact verification, docs publishing.
- **Release:** build from immutable refs; SBOM/provenance and signatures when needed;
  least-privilege publish credentials; smoke-test the published artifact.

Version workflow generators, reusable actions, runner selection, test configuration, dependency
pins. Never expose secrets to untrusted fork PRs.

## Stack decisions and connector setup

At every material choice during Design (language, hosting, DB, domain, CI/CD tool, at minimum),
follow `references/stack-decision-process.md`: present an options table (2-3 real candidates,
pros/cons), then two ordered questions — self-hosted or managed first, pricing tier only if
managed — never a raw budget figure — and cite real evidence for the decision, recorded in
`.athene/state.md`'s Decisions made.

Once a stack choice is made, follow `references/connector-detection.md`: detect whether the
matching MCP/connector exists per the current platform (Claude Code, Codex, Cursor), auto-set it
up when that's supported (Claude Code and Codex have a CLI add command; Cursor doesn't — manual
guide only there), and hand over a real, usable manual guide otherwise — never claim auto-setup
for a connector that isn't actually AI-configurable.

## Evidence-backed architecture and the engineering quality bar

For each nontrivial architecture decision (not a stack pick — how a feature's data flows, where
state lives, how a system handles failure), follow `references/architecture-decision-template.md`:
check reversibility first (skip the full template if the choice is changeable in under a week),
otherwise work through problem/constraints/requirements → options with tradeoffs → the
quality-bar check (non-functional targets, security, performance, operations, edge cases) →
decision → consequences → revisit trigger.

Back the decision with real evidence, not memory: consult `references/engineering-source-index.md`
for the topic. If no entry covers it, follow `references/source-index-live-search.md`'s
live-search + issue-drafting flow instead of skipping evidence.

## Governance artifacts

Write these once, early — during Design, before Implementation starts generating real diffs — not
retrofitted later. `templates/` below holds this skill's own copies of Audit's governance files
(copied, not re-authored, per Audit's own note that these are the one real source of this
content); mirroring keeps each skill's `templates/` independent, so there's no shared-at-runtime
location across skills.

**Fixed baseline — always written, regardless of framing or risk tier:**
1. **`templates/CONTRIBUTING.md`** → target repo's `CONTRIBUTING.md`, plus
   **`templates/debt-ledger.sh`** → target repo's `scripts/debt-ledger.sh` (copy both together —
   CONTRIBUTING.md names the command, so it has to actually exist). Conventional Commits
   (`feat/fix/chore/docs/refactor/test/perf/ci/build`), no-AI-attribution, and the `athene:`
   shortcut-marker convention.
2. **`templates/pull_request_template.md`** → `.github/pull_request_template.md`.
3. **`templates/ISSUE_TEMPLATE/bug_report.md`** and **`templates/ISSUE_TEMPLATE/feature_request.md`**
   → `.github/ISSUE_TEMPLATE/`.
4. **Claude Code only:** set `attribution.commit`/`attribution.pr` to `""` (and `sessionUrl` to
   `false` if session links are also prohibited) in the target repo's `.claude/settings.json` —
   `includeCoAuthoredBy` alone doesn't disable attribution once either of those keys is already
   set. Codex and Cursor have no equivalent setting; the rule lives in the doc only there.

**Framing and risk tier** — same indirect-question approach as Audit, not a form: check
`.athene/state.md`'s Decisions made first — if Athene: Product Discovery already recorded a
framing decision on its way out, read it back rather than re-asking. Decisions made is
append-only, so if more than one framing entry exists, the most recent one governs — a later
entry means the framing was revisited, not that an earlier one is still live. Otherwise infer from what
Design has already surfaced (stack choices, who the repo is for, whether payments/auth/PII are in
scope); ask once, conversationally, only when genuinely ambiguous. Use
`references/governance-doc-set-mapping.md`'s own criteria directly — don't restate them here, that
creates a second copy that can drift. Record framing, risk tier, and why in `.athene/state.md`'s
Decisions made.

**Variable layer** — look up the (framing, risk tier) pair in that same table and write exactly the
doc set the row names, nothing more: `templates/CODEOWNERS` (check `.github/CODEOWNERS`, root, then
`docs/CODEOWNERS` first — first match wins, leave an existing one alone; when writing a new one,
replace `@REPLACE_WITH_DEFAULT_OWNER` with a real owner who has repo write access and confirm the
file no longer contains the placeholder — a CODEOWNERS file the review gate can see but that names
no real owner satisfies the gate's existence check without actually routing review to anyone),
`templates/SECURITY.md` (only list a channel confirmed to actually work), `templates/commitlint.config.mjs`
+ `templates/workflows/commitlint.yml` (check the full documented commitlint config-file list before
assuming none exists; leave an existing config unchanged; set `configFile` only for formats the
action supports; skip and record the case if the detected format, its dependencies, or existing CI
can't be supported — same handling as Audit's own commitlint step, not restated here), and
`templates/RELEASE.md`. `none` is a valid, common result — don't add extra docs because it feels
more thorough.

**Review/merge gate:** copy `templates/set-review-gate.sh` → target repo's
`scripts/set-review-gate.sh`, and follow `references/review-gate.md` for what it does and the
default-off rationale — don't run it unprompted. Every PR this skill authors gets a self-review
subagent pass first, then waits on whoever's configured as reviewer before merge; that queue
discipline holds regardless of the toggle. Offer the toggle, note the result in Decisions made, and
only run `set-review-gate.sh ... on` if the user asks for it turned on now — but first confirm a
real CODEOWNERS owner is in place (see above) and that at least one eligible reviewer other than
whoever authors this skill's PRs can actually approve them; a solo-writer repo with the gate on
blocks every PR until someone else is added or the gate is turned back off.

## State handling

Create or update `.athene/state.md` as a committed plain-Markdown file, self-contained spec below
(this file doesn't travel with the skill once mirrored elsewhere, so don't cross-reference it by
path). Write it at the end of this skill's turn/session, not mid-task — a reader (including this
skill, next time it reads its own state back) should never see an intermediate phase or an
incomplete decision list:

- Four headings, in this exact order, each required — `none`/`n/a` rather than omitting one:
  `## Active skill`, `## Current phase`, `## Decisions made`, `## Open questions`.
- **Active skill:** `athene` — this skill's own frontmatter `name`, while this skill owns the
  repo. Set to `athene-launch`'s frontmatter name once handed off (see below) — not yet a real
  file in this repo, so until it exists, name it anyway and flag in Open questions that the
  named skill isn't packaged yet, same pattern Audit and Resume already use for this exact gap.
- **Current phase:** one of the lifecycle stages above, while `Active skill` is `athene`. Once
  handed off to Launch, this field belongs to Launch's own lifecycle, not this skill's — see
  the Handoff section below for what value to leave it at.
- **Decisions made:** bullet list, append-only. What was chosen and why, in the order decided —
  stack choices, architecture decisions, governance artifacts written, each with its rationale.
- **Open questions:** bullet list. Anything genuinely unresolved. `none` if nothing's outstanding.

## Handoff

Once the repo foundation, decision records, and governance artifacts are in place, update
`.athene/state.md`: set `Active skill` to `athene-launch` and `Current phase` to `handoff` — not
a Build-lifecycle value like "release and post-merge," which belongs to this skill's own
vocabulary, not Launch's. Launch defines its own lifecycle; `handoff` is the one shared value
both skills agree means "just arrived, haven't started your own stages yet," so Launch (or
Resume reading on Launch's behalf) never receives a phase name from a lifecycle it doesn't run.

Then read and follow the Athene: Launch skill file directly — a plain read-and-follow
instruction, not a platform-specific invoke call. That skill doesn't exist in this repo yet; if
it isn't packaged where this skill is installed, say so explicitly and stop there rather than
claiming a handoff that can't happen, instead of guessing at Launch's behavior.
