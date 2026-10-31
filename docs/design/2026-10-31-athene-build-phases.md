# Athene — Build Phases

Date: 2026-10-31
Status: phase breakdown derived from `2026-10-31-athene-design.md`. No issues created yet — this
doc is the basis for issue-by-issue work once phases are confirmed.

Each phase lists its goal, deliverables, what it depends on, and how to know it's done. Phases are
ordered so nothing is built against a dependency that doesn't exist yet.

## Phase 0 — Repo scaffold and skill-authoring conventions

**Goal:** fix the shape every later skill gets built into, so phases 1+ aren't re-deciding
structure mid-build.

**Deliverables:**
- Directory convention for this repo: each skill lives once, canonically, at
  `skills/<name>/SKILL.md`; a build/packaging step mirrors it into `.agents/skills/<name>/SKILL.md`
  (native to Codex + Cursor) and `.claude/skills/<name>/SKILL.md` (native to Claude Code) for
  distribution into target projects.
- `.athene/state.md` schema: fields for current phase, decisions made so far, open questions,
  which skill is active. Must be readable by both Resume and Audit.
- Template bootstrap snippets for target repos: a short block to append to a target project's
  `CLAUDE.md` and `AGENTS.md` telling the agent to check `.athene/state.md` first and route to
  Resume or Audit accordingly, before anything description-matching would normally decide.
- A skill-description style guide (short) — since description quality is the single highest-
  leverage thing on every platform (see platform-mechanics section of the design doc).

**Depends on:** nothing.

**Done when:** the conventions above exist as committed docs/templates in this repo, with no
skill content written against them yet.

## Phase 1 — Athene: Resume and Athene: Audit

**Goal:** state-tracking exists before any build-phase skill relies on it.

**Deliverables:**
- Athene: Resume — reads `.athene/state.md`; if found, reports current phase/decisions/open
  questions and continues; if not found, hands off to Athene: Audit.
- Athene: Audit — scans an existing, non-Athene repo (structure, policies, CI, ownership signals),
  builds the governance artifacts retroactively (same rules Phase 2 defines), and bootstraps
  `.athene/state.md` so Resume can track the project going forward.

**Depends on:** Phase 0 (state-file schema, bootstrap snippets).

**Done when:** both skills work stand-alone against a real repo — one freshly Athene-tracked
(Resume path), one legacy/untouched (Audit path) — and both leave a valid state file behind.

## Phase 2 — Governance artifact generation

**Goal:** PR/issue/review rules exist before the review-gate behavior (Phase 3/5) can be tested
against them.

**Deliverables:**
- Fixed baseline, always written: Conventional Commits convention doc
  (`feat/fix/chore/docs/refactor/test/perf/ci/build`), standard PR template, standard issue
  templates (bug repro fields, feature request), and a no-AI-attribution-trailer rule for commits
  and PRs. On Claude Code this also means setting `includeCoAuthoredBy: false` in the target
  repo's `.claude/settings.json`; Codex and Cursor have no equivalent toggle, so the rule is
  instruction-only there.
- Variable layer: risk-tier → governance-doc-set mapping table (which extra docs appear for which
  combination of project framing — opensource/startup/personal/research — and risk tier from the
  existing merge-conditions table). Solo/fun stays light; opensource/startup gets the full set.
- CODEOWNERS-style artifact folding in: review/merge-gate toggle (default off = documented
  convention only; on = real technical gate), who reviews, who merges, who creates issues/PRs by
  default (AI agent, user-overridable).
- Default git host assumption: GitHub for v1.

**Depends on:** Phase 1 (Audit needs these same rules to retrofit onto legacy repos).

**Done when:** running the governance-generation step against a fresh repo and against a legacy
repo (via Audit) both produce a correct, risk-scaled artifact set, and the review-gate toggle
visibly changes behavior when flipped.

## Phase 3 — Stack-decision flow

**Goal:** material build choices (language, hosting, DB, domain, CI/CD tool) get decided with
real options and real connector setup, not just picked by the agent.

**Deliverables:**
- Options-table generator: pros/cons per choice, then the free vs. paid vs. which-paid-tier
  question (never a raw budget number).
- MCP/connector auto-detection per platform: Claude Code `.mcp.json`/settings, Codex config,
  Cursor config. Falls back to asking the user only when detection is inconclusive.
- Setup path: AI sets the connector up when it can; otherwise hands the user a manual guide.
- Indirect project-framing question wording (opensource/startup/personal/research) — asked once,
  early, feeds both this phase and Phase 2's variable layer.

**Depends on:** Phase 2 (risk tier/framing already established feeds the options shown here).

**Done when:** a real stack decision (e.g. "pick a database") produces an options table, a
tier-not-budget question, and a correct connector-detected/set-up/manual-guide outcome on at least
one of the three platforms.

## Phase 4 — Curated source-index and self-growing flow

**Goal:** architecture decisions get backed by real engineering sources, and gaps in the index get
filled through the maintainers, not silently.

**Deliverables:**
- Starter static index: real research populating source → topic mappings (at minimum: ecommerce,
  payments, auth, social, messaging/queueing, search, ML-serving). Lives once, shared, bundled
  with the skill package — not per target repo.
- Live-search fallback for an uncovered topic, used for the build at hand.
- On finding a new source: draft an issue on Athene's own repo proposing it (name, topic, why),
  rather than silently appending to the shared file.
- Resolve the cross-repo write-access question this implies (an agent running inside someone
  else's target repo needs a way to file an issue against *this* repo).

**Depends on:** Phase 3 (architecture decisions are what trigger a source-index lookup).

**Done when:** a decision on an indexed topic cites the right source, a decision on an unindexed
topic produces a live search plus a correctly drafted issue here, and the cross-repo credential
question has a working answer (even if the answer is "ask the user to supply a token").

## Phase 5 — End-to-end chaining

**Goal:** Discovery → Athene (build) → Launch runs as one continuous flow without the user typing
each slash command.

**Deliverables:**
- Each skill file ends with an explicit "read and follow the next skill file directly" instruction
  (plain file-read, portable across all three platforms).
- Discovery's branch for an already-Athene-tracked repo: "new feature, or new idea/direction
  overall?"
- Launch's loop-back-to-Discovery condition (pivot/new hypothesis) vs. cycle-end condition.

**Depends on:** Phases 1-4 all existing in working form, since this phase wires them together
rather than building anything new.

**Done when:** one real run, started from Discovery on a fresh idea, reaches a Launch decision
without the user invoking Athene (build) or Launch by name.

## Phase 6 — Multi-platform packaging

**Goal:** prove the same behavior holds on Claude Code, Codex, and Cursor, not just the platform
used during phases 0-5.

**Deliverables:**
- Mirroring step from the canonical `skills/<name>/SKILL.md` into `.agents/skills/` and
  `.claude/skills/` (per Phase 0's convention).
- `agents/openai.yaml` fleshed out for all five skills (display metadata, implicit-invocation
  policy, required-tool dependencies) beyond the current placeholder.
- Verification pass on Cursor (which reads `.agents/skills/` and `.claude/skills/` natively, so
  this is confirmation, not new packaging work) and on Codex.

**Depends on:** Phase 5 (nothing to package until the flow itself works).

**Done when:** the same end-to-end run from Phase 5 is reproduced on Claude Code, Codex, and
Cursor without platform-specific skill content changes.
