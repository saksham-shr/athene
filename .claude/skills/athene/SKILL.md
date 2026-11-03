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
  - **`athene`:** continue below, picking up at whatever `Current phase` names.
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
   compatibility/migration, tests, rollback. This is where stack decisions and connector setup
   apply — see the dedicated section below. Evidence-backed architecture and the engineering
   quality bar also apply here, but aren't wired into this skeleton yet — see the follow-up
   issue that wires those in.
4. **Implementation** — supported toolchains, reproducible bootstrap/lint/targeted-test/docs-
   preview/debugging paths. Focused diffs, risk-proportionate tests, docs/release impact
   assessed.
5. **PR intake** — drafts until ready. Non-trivial external work needs an accepted issue or a
   named sponsor, a concise human-written summary, compatibility disclosure, performance
   evidence where relevant. Run CLA/license/security checks early.
6. **Review** — route by path ownership plus fallback. Evaluate correctness, tests, operations,
   docs, compatibility, performance, security, maintainability. Re-review when the approved
   surface materially changes. **The self-review-then-wait-on-reviewer gate described in the
   design doc isn't wired into this skeleton yet — see the follow-up issue.**
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

## Governance artifacts

**Not yet wired into this skeleton** — see the follow-up issue that wires in the fixed baseline
(Conventional Commits, PR/issue templates, no-AI-attribution, `athene:` shortcut markers) and the
risk-scaled variable layer, both already built for Athene: Audit and meant to be reused here, not
re-authored.

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
