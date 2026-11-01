---
name: athene-audit
description: Adopt Athene onto a repo never set up with it - scan structure, policies, CI, and ownership signals, write fixed-baseline governance docs, and bootstrap .athene/state.md. Skip if .athene/state.md already exists - use Athene: Resume instead.
---

# Athene: Audit

Use this skill the first time Athene touches an existing repo — adopting onto something already
built, not starting greenfield. Distinct trigger from "start building": this is "retrofit process
onto what's already here."

## Check for existing state first

If `.athene/state.md` already exists at the repo root, this isn't a fresh adoption — read and
follow Athene: Resume instead. Stop here.

## Scan before writing anything

Read, don't assume. Inspect:
- **Structure:** language(s), build tooling, test setup, directory layout.
- **Policies:** existing `CONTRIBUTING.md`, PR/issue templates, `SECURITY.md`, license.
- **CI:** workflow files and what they currently check.
- **Ownership signals:** `CODEOWNERS`, branch protection rules, who merges today.

Report what's found before changing anything — don't overwrite an existing convention silently.

## Determine framing and risk tier

Needed to pick the right governance-doc set from this skill's own
`references/governance-doc-set-mapping.md` below. Infer first; only ask when the scan genuinely
doesn't make it obvious — this isn't a form to fill out, per Athene's own non-goal of feeling
bureaucratic or like an interrogation.

**Framing** (`personal`, `research`, `opensource`, `startup`):
- Infer from the scan: a public license + multiple non-owner contributors + a contributor-focused
  `CONTRIBUTING.md` reads as `opensource`. Billing/payments code, a pricing page, or a SaaS-shaped
  structure reads as `startup`. Heavy `.ipynb`/LaTeX/citations with one author reads as `research`.
  A single committer, no license, hobby-project structure reads as `personal`.
- If genuinely ambiguous, **or the scan matches signals for more than one category** (e.g. a
  public license with contributors *and* billing code — `opensource` vs. `startup` pick different
  doc sets at Medium risk, so don't guess), ask once, conversationally — never list the four
  category names themselves, that reads as a form: *"One thing before I go further — who's this
  really for: just you right now, outside contributors or users you don't control, a team or
  customers depending on it, or is it feeding research or coursework?"* Map the answer to a
  category yourself; don't make the user pick a label.
- Record the result and why in `.athene/state.md`'s Decisions made, same as any other decision.

**Risk tier** (`Low`, `Medium`, `High` — per `references/governance-doc-set-mapping.md`'s own
criteria — use the full criteria below, not a subset, or the wrong doc set gets selected):
- `High`: auth/credential handling, payment integration, PII in the data model, a CI/release-
  policy surface (deploy credentials, signing, publish pipelines), or real paying/external users
  depending on the project.
- `Medium`: user-visible API changes or schema migrations happen, but none of the `High` signals
  above apply.
- `Low`: neither — internal-only, no sensitive surface, no migrations/API changes of consequence.
- Fine to ask directly if ambiguous — it's a technical question, not a social one, so the
  indirect-phrasing rule above doesn't apply here. Ask broadly enough to separate all three tiers,
  not just High from everything else: *"Does this handle payments, user credentials, other
  personal data, or deploy/release credentials — or does it change APIs or run schema migrations
  without any of that?"*
- Record the result and why alongside framing.

## Write the fixed baseline

Copy these template files from this skill's own `templates/` directory into the target repo if
not already present there, adapting wording to fit what the scan above found rather than
overwriting a working existing convention. (These templates are the one real source of this
content — mirroring copies each skill's directory independently, so there's no shared-at-runtime
location across skills yet. When the `athene` build skill is built, copy these same files into
its own `templates/` directory rather than re-authoring the content.)

1. **`templates/CONTRIBUTING.md`** → target repo's `CONTRIBUTING.md` — Conventional Commits
   convention (`feat/fix/chore/docs/refactor/test/perf/ci/build`) and the no-AI-attribution rule
   together in one doc, not split across files.
2. **`templates/pull_request_template.md`** → target repo's `.github/pull_request_template.md` —
   three sections: Summary, Why, Test plan.
3. **`templates/ISSUE_TEMPLATE/bug_report.md`** and **`templates/ISSUE_TEMPLATE/feature_request.md`**
   → target repo's `.github/ISSUE_TEMPLATE/` — copy both, unchanged unless the scan found a reason
   to adapt wording.
4. **Claude Code only:** `includeCoAuthoredBy` is deprecated and is ignored once
   `attribution.commit` or `attribution.pr` is already set — so setting it alone on a repo that
   already has either key leaves attribution on. Set the current controls instead, in the target
   repo's `.claude/settings.json`:
   ```json
   {
     "attribution": {
       "commit": "",
       "pr": "",
       "sessionUrl": false
     }
   }
   ```
   `sessionUrl: false` only if session links are also prohibited for this repo. Codex and Cursor
   have no equivalent setting — for those, the rule lives in the doc only.

## Write the variable layer

Look up the (framing, risk tier) pair from the previous step in this skill's own
`references/governance-doc-set-mapping.md` table and write exactly the doc set that row names —
nothing more, nothing less. `none` is a valid, common result (e.g. `personal`/`Low`); don't
invent extra docs because it feels more thorough.

Template files for each possible doc, all in this skill's own `templates/` directory, same
copy-if-not-already-present rule as the fixed baseline:
- **`templates/CODEOWNERS`** → GitHub reads `.github/CODEOWNERS`, then root `CODEOWNERS`, then
  `docs/CODEOWNERS`, first match wins — check all three, in that order, before creating a new
  one. If one already exists anywhere in that order, it's authoritative; leave it alone rather
  than creating a root file that silently takes precedence over it. Only write to
  `.github/CODEOWNERS` when none of the three already exist. Replace `@REPLACE_WITH_DEFAULT_OWNER`
  with a real owner who has write access; the placeholder alone satisfies nothing.
- **`templates/SECURITY.md`** → target repo's `SECURITY.md` — only list a channel that actually
  works: keep the GitHub line only if private vulnerability reporting is confirmed enabled for
  the target repo, keep the email line only if the scan found a real address (never ship the
  placeholder domain as if it were live). If neither is confirmed, say so in the doc and flag it
  in Decisions made as still needing a real channel — don't advertise one you haven't verified.
- **`templates/commitlint.config.mjs`** → target repo's `commitlint.config.mjs`, plus
  **`templates/workflows/commitlint.yml`** → target repo's `.github/workflows/commitlint.yml` —
  both together; the config alone does nothing without the CI step that runs it. First check for
  *any* existing commitlint config — don't match the literal filename `commitlint.config.mjs`
  only. commitlint's documented search covers exactly: `.commitlintrc`, `.commitlintrc.json`,
  `.commitlintrc.yaml`, `.commitlintrc.yml`, `.commitlintrc.js`, `.commitlintrc.cjs`,
  `.commitlintrc.mjs`, `.commitlintrc.ts`, `.commitlintrc.cts`, `.commitlintrc.mts`,
  `commitlint.config.js`, `commitlint.config.cjs`, `commitlint.config.mjs`,
  `commitlint.config.ts`, `commitlint.config.cts`, `commitlint.config.mts`, or a `commitlint` key
  in `package.json` or `package.yaml`. That exact list, not a loose `commitlint.config.*` glob —
  a glob also matches unrelated files like a stray `.commitlintrc.bak`, which commitlint itself
  would never resolve as config. If the target repo already has `commitlint` as a dependency,
  that's itself a strong signal a config exists somewhere in this list; find and respect it
  rather than assuming. Adding
  a second config alongside an existing one doesn't merge rules; commitlint resolves to whichever
  one its config search finds, which can silently override a different existing policy. If any
  form already exists, leave the config alone — same "don't overwrite a working existing
  convention" rule as everything else here. **The workflow needs the same care, separately:**
  if an alternate config was found and CI doesn't already run commitlint, don't copy
  `templates/workflows/commitlint.yml` unmodified — `wagoid/commitlint-github-action@v6` with no
  `configFile` set only checks `./commitlint.config.mjs`; if an alternate-named config exists and
  isn't pointed to, the action silently falls back to `@commitlint/config-conventional` instead
  of the repo's real rules; wire the detected path into `with: configFile:` before copying. If CI
  already runs commitlint some other way, skip adding the workflow entirely.
- **`templates/RELEASE.md`** → target repo's `RELEASE.md` — release/tag policy doc.

## Offer the review-gate toggle

Copy **`templates/set-review-gate.sh`** → target repo's `scripts/set-review-gate.sh` (same
copy-if-not-already-present rule as the other templates). Tell the user it exists and what it
does, per this skill's own `references/review-gate.md` — don't run it. Default is off: that's the
right state for a repo that just got its baseline, and flipping it on is the user's call, not
something Audit decides on their behalf. If they want it on now, run it per that doc's
instructions; otherwise just note it was offered.

## Bootstrap state

Create `.athene/state.md` as a committed plain-Markdown file so Resume can track the project
going forward — self-contained spec below, since `docs/state-schema.md` lives only in Athene's
own repo and isn't packaged alongside this skill when mirrored into a target repo:

- Four headings, in this exact order, each required — use `none`/`n/a` rather than omitting one:
  `## Active skill`, `## Current phase`, `## Decisions made`, `## Open questions`.
- **Active skill:** `athene` — the build skill's frontmatter `name` (Athene: repo + build +
  architecture), not a descriptive title; Resume needs a real file to find. Audit's job is
  retrofit, not ongoing ownership — hand off once the baseline above is written. **Caveat:** that
  build skill isn't packaged in this repo yet (Phase 2+, not yet built). If no skill named `athene`
  exists where this skill is installed, say so explicitly and report everything else in this file
  as-is, rather than claiming a handoff that can't actually happen.
- **Current phase:** intake.
- **Decisions made:** bullet list, append-only. Record framing, risk tier, and every baseline and
  variable-layer artifact written (or found already present and left alone), in the order decided
  — what was done and why.
- **Open questions:** bullet list. Anything left unresolved — e.g. a placeholder `SECURITY.md`
  contact that still needs a real address, or whether the review-gate toggle should be turned on.
  `none` if nothing's outstanding.
