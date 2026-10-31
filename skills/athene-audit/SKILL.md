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

## Write the fixed baseline

This is the scope of this skill for now — not the full variable governance layer (risk-tier-scaled
docs like CODEOWNERS maps, SECURITY.md, release/tag policy) described in Athene's own design doc.
That layer depends on a risk-tier → governance-doc-set mapping table that doesn't exist yet
(Phase 2, not yet built). Write only what's concretely specified below; don't invent the rest.

Write these into the target repo if not already present, adapting wording to fit what the scan
above found rather than overwriting a working existing convention:

1. **Commit convention doc** — Conventional Commits: `feat/fix/chore/docs/refactor/test/perf/ci/
   build`.
2. **PR template** (`.github/pull_request_template.md`) — three sections: Summary, Why, Test plan.
3. **Issue templates** (`.github/ISSUE_TEMPLATE/`) — bug report (repro steps, expected vs. actual,
   environment) and feature request.
4. **No-AI-attribution rule** — commit messages and PR descriptions never carry an AI attribution/
   co-author trailer, regardless of which agent wrote them. Document this in the commit convention
   doc from step 1, not a separate file.
5. **Claude Code only:** `includeCoAuthoredBy` is deprecated and is ignored once
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
- **Decisions made:** bullet list, append-only. List each baseline artifact written (or found
  already present and left alone) in step order above — what was done and why.
- **Open questions:** bullet list. Note that the variable governance layer (risk-tier scaling) is
  deferred until Phase 2 exists — a known, intentional gap, not an oversight.
