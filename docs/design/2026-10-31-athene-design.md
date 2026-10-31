# Athene — Design Document

Date: 2026-10-31
Status: pre-build design, to hand to builder for phased/issue-driven implementation.

## Intent and why

Non-coders (and coders) using AI coding agents today get code that works but skips engineering
practices nobody told the agent to follow: no issue/PR discipline, no review gate, no CI/CD
design, no evidence-backed architecture choices, no governance. Athene is a connected set of
skills that makes a coding agent behave like a disciplined engineering team by default — discover
the right thing, build it with real repo hygiene, launch small, and let the agent resume or
retrofit this onto any repo, old or new.

The three original skills (Product Discovery, Athene repo/build, Launch) already exist as
standalone drafts at
`C:\Users\saksh\Documents\Codex\2026-10-31\i-x20\outputs\` (handbook:
`athene-comprehensive-handbook.md`; skills: `athene-product-discovery/SKILL.md`,
`athene/SKILL.md`, `athene-launch/SKILL.md`). This design adds: automatic handoff between them,
budget-aware stack decisions backed by real engineering sources, MCP/connector auto-setup,
generated repo-governance artifacts, a PR review gate, and two new skills for legacy-repo
onboarding and session resume.

## Skills (5) and the flow

1. **Athene: Product Discovery** — turns an idea into an approved product brief (problem, user,
   outcome, now/later/not-now scope, constraints, validation plan). Asks an indirect
   project-framing question early (opensource / startup / personal / research — never a direct
   budget question). If run inside a repo that already has an Athene state file (see Resume
   below), it detects that and asks instead: "new feature on this, or a new idea/direction
   overall?" — branching rather than restarting discovery from zero.
   - **Handoff:** once the user approves the brief, the skill reads and follows the Athene
     (repo/build) skill file directly — no slash command from the user needed.

2. **Athene (repo + build + architecture)** — establishes the repo's operating model before any
   code is written, then builds. Lifecycle stages follow the handbook's existing model (intake,
   triage, design, implementation, PR intake, review, CI/merge, release). Default git host for v1
   is GitHub (CODEOWNERS, PR/issue templates, branch protection all assume it) — other hosts are a
   later extension, not v1 scope. On start, this skill always scans the target repo for an
   existing Athene footprint/state file first; if absent, it hands off to Athene: Audit instead of
   proceeding as if the repo were greenfield — this is how skill 2 and skill 4 disambiguate
   without relying on how the user phrased the request. New behavior:
   - **Stack decisions:** at every material choice (language, hosting, DB, domain, CI/CD tool),
     presents an options table (pros/cons) and asks the user free vs. paid vs. which-paid-tier —
     never a raw budget figure.
   - **Evidence-backed architecture:** for each nontrivial design decision (e.g. "ecommerce
     inventory system"), consults a curated reference file mapping engineering sources to topics
     (e.g. Stripe eng blog → payments, AWS Builders' Library → distributed systems, Shopify eng →
     commerce at scale). This file is a single shared asset bundled with the Athene skill package
     itself — one copy reused across every repo and every user, not instantiated per target repo.
     If no entry covers the topic needed, the agent searches live for that build. It does **not**
     silently append the new source to the shared file. Instead it opens an AI-drafted issue on
     Athene's own repo proposing the new source (name, topic, why). The user who hit the gap can
     self-assign and send a PR for it, or just leave the issue for Athene's maintainers to handle.
     (Builder note: this means an agent running inside someone else's target repo needs a way to
     file issues against Athene's own repo — cross-repo write access/credentials — which is a real
     constraint, not just a local file edit.)
   - **MCP/connector setup:** once a stack choice is made, auto-detects whether a connector/MCP
     exists and is wired, by reading the current agent's own config (Claude Code `.mcp.json` /
     settings, Codex config, Cursor config). Only asks the user when detection is inconclusive. If
     missing and AI-setupable, sets it up; otherwise hands the user a manual setup guide.
   - **Governance artifacts:** before coding starts, writes real committed `.md` files into the
     target repo — not just internal skill guidance. Two layers:
     - *Fixed baseline* (always written): Conventional Commits convention
       (`feat/fix/chore/docs/refactor/test/perf/ci/build`), a standard PR template (summary, why,
       test plan), standard issue templates (bug repro fields, feature request), and a rule that
       commit messages and PR descriptions never carry an AI attribution/co-author trailer
       regardless of which agent wrote them. On Claude Code specifically, Athene also sets
       `includeCoAuthoredBy: false` in the repo's own `.claude/settings.json` so the trailer is
       suppressed at the tool level, not just by instruction; Codex and Cursor have no equivalent
       setting, so for those the no-attribution rule lives purely in this governance doc and the
       skill's own commit/PR instructions.
     - *Variable layer* (scaled by project framing + risk tier from the existing merge-conditions
       table): how strictly enforced, and which extra docs exist — e.g. a solo/fun project skips
       CODEOWNERS and SECURITY.md; an opensource/startup project gets commitlint in CI, a full
       CODEOWNERS-style map, SECURITY.md, and a release/tag policy doc.
   - **Review/merge gate, folded into the CODEOWNERS-style artifact:** every AI-written PR first
     gets a subagent self-review pass, then is meant to wait on code review from whoever is
     configured as reviewer (user, another AI agent, or a named person) before merge. Whether that
     wait is actually enforced is a toggle, default **off**: for non-technical users it's a
     documented convention the agent follows by discipline only, no technical block. Experienced
     users can flip it **on**, which must then be a real technical gate (branch protection /
     required status check on the host) so the AI genuinely cannot merge an unreviewed PR. The
     same artifact records who merges, and who creates issues/PRs by default (AI agent,
     user-overridable).
   - **Handoff:** once the repo foundation, decision records, and governance artifacts are in
     place, reads and follows the Launch skill file directly.

3. **Athene: Launch** — defines the smallest launchable slice, pairs assumptions with evidence and
   decision rules, builds the launch/marketing plan, confirms release readiness, and runs the
   post-launch review (continue / iterate / expand / stop).
   - **Handoff:** loops back to Discovery only if the evidence points to a pivot or new
     hypothesis; otherwise the cycle for that feature/release ends.

4. **Athene: Audit** (new) — for a repo that was never set up with Athene. Scans existing
   structure, policies, CI, ownership signals; builds the governance artifacts retroactively
   (same fixed baseline + variable layer rules as skill 2); bootstraps the state file described
   below so the project can be tracked going forward. Distinct trigger from skill 2's
   "start building" trigger — this one is "adopt Athene onto something that already exists."

5. **Athene: Resume** (new) — distinct skill from Audit. On start, checks for an existing Athene
   state file in the repo:
   - **Found:** reports where the work last left off (current phase, decisions already made, open
     questions) and continues from there.
   - **Not found:** hands off to Athene: Audit instead, since there's nothing to resume.

## Persistent state

All three build-phase skills (Discovery, Athene build, Launch) write/update a state file in the
repo as they progress — current phase, decisions made, open questions, which skill is active.
Exact location/format (e.g. `.athene/state.md`) is left to the builder; constraint is that it must
be readable by Resume and Audit, and should not block normal repo tooling (likely committed, plain
markdown, not gitignored, so it survives across machines/agents/sessions).

## Issue and PR conventions (for this repo's own build, researched 2026-10-31)

Standard across most open-source repos, and used for Athene's own build issues from Phase 0 on:

- **Title:** same type prefix as the Conventional Commits baseline (`feat/fix/chore/docs/refactor/
  test/perf/ci/build`) plus a scope, e.g. `chore(state): define .athene/state.md schema`. Keeps
  issue titles and the commits that close them readable as one vocabulary.
- **Body:** four sections — **Context** (what and why, one or two sentences), **Tasks** (a
  `- [ ]` checklist; GitHub renders it as progress and one issue should cover one coherent piece of
  work, not several), **Acceptance criteria** (specific, observable, testable — not "write good
  code"), **Depends on** (links to issues that must land first, or "none").
- PRs reference the issue they close (`Closes #N`) rather than restating its content.
- **`Closes #N` goes in the PR description, never in a commit message.** GitHub auto-closes on
  that keyword the moment the commit lands on the default branch — if work is committed straight
  to `main` with no PR, the issue closes with no review step at all. Keep closing keywords out of
  commit messages so every close actually passes through a PR. A commit message states what
  changed, nothing about which issue it closes.

This is the same shape the fixed-baseline issue templates (Phase 2) generate for target-repo
issues — Athene's own repo follows its own rule.

**Creating a PR via `gh` CLI (researched 2026-10-31):**
- Push the branch first — `git push -u origin <branch>` — the branch must exist on the remote
  before `gh pr create` can target it.
- Pass the body through a single-quoted heredoc, not an inline string: `gh pr create --body "$(cat
  <<'EOF' ... EOF)"`. The quoted delimiter (`<<'EOF'`, not `<<EOF`) stops the shell from expanding
  `$`, backticks, or other special characters inside the markdown body.
- Pass `--base <branch>` explicitly whenever the target isn't the default branch; don't rely on
  `gh`'s guess.
- `Closes #N` lives inside this heredoc body, per the rule above — never in the commit message.

## Platforms

Claude Code, Codex, Cursor, for now. Each skill ships per-platform packaging:
- Claude Code: `SKILL.md` (existing format).
- Codex: existing `agents/openai.yaml` stub plus the `SKILL.md` content — needs the stub fleshed
  out beyond the current placeholder `display_name`/`short_description`.
- Cursor: no variant exists yet; needs a new packaging format (e.g. `.cursor/rules`-style) — left
  to the builder to design against Cursor's actual rules mechanism.

## Chaining mechanism

Portable across all three platforms: each skill's file ends with an explicit instruction to read
and follow the next skill's file directly, rather than relying on a platform-specific
"invoke skill" tool (which not all three harnesses have). This is a plain file-read instruction,
not a special tool call.

## Non-goals / anti-goals

- Not aiming for a universal numeric process score or one-size-fits-all policy set — scope and
  strictness always scale with project framing and risk tier (per existing handbook model).
- Not meant to feel bureaucratic or intimidating to a non-coder; process detail should run mostly
  in the background via indirect questions and generated artifacts, not interrogation. (User
  confirmed this is handled by the design as-is — not a separate gate to re-litigate.)
- No live-research case-study files shipped inside the actual skill (the three case studies in
  the current `athene/references/` folder were planning-only research and are not part of the
  shipped skill content).

## Left to the builder

- Exact state-file schema/location and how Discovery/Build/Launch each update it mid-phase.
- Exact format and starter contents of the curated source-index reference file (list of
  engineering blogs/papers and the topics each is authoritative on) — needs real research to
  populate before first use, covering common domains (ecommerce, payments, auth, social,
  messaging/queueing, search, ML-serving, at minimum).
- Per-agent MCP/connector config file locations and detection logic for Claude Code, Codex, and
  Cursor specifically (paths, formats).
- The exact wording/flow of the indirect project-framing question and the free/paid/tier question
  at each stack decision point.
- Risk-tier → governance-doc-set mapping table (which docs appear at which combination of project
  framing and risk tier) — the design above establishes the principle (fixed baseline + scaled
  variable layer) but not the literal table.
- Fleshing out `agents/openai.yaml` for all five skills beyond the current placeholder.

## Platform mechanics (researched 2026-10-31)

How each target platform actually discovers/loads/triggers a skill — confirmed against official
docs (`code.claude.com`, `learn.chatgpt.com`/`developers.openai.com`, `cursor.com`).

**Claude Code**
- Skill = folder `<name>/SKILL.md` under `.claude/skills/` (project, walks up to repo root) or
  `~/.claude/skills/` (personal), or inside a plugin.
- Frontmatter: `name`, `description` required. `description` is the only thing always in context —
  it is what decides whether Claude auto-invokes the skill, so it must front-load trigger words.
  Full SKILL.md body loads only once triggered (progressive disclosure).
- Invocation: model-invoked automatically from the description match, or user-invoked via
  `/<name>`. `user-invocable: false` hides it from the slash-command list but Claude can still
  invoke it.
- **Flat only** — nested category folders (`category/skill/SKILL.md`) are not discovered.
- No always-loaded equivalent for skills themselves, but `CLAUDE.md` at repo root IS always loaded
  every session — usable as the bootstrap hook (see below).

**Codex CLI**
- Skill = folder with `SKILL.md` under `.agents/skills/` (cwd + every parent up to repo root),
  `$HOME/.agents/skills/` (user), `/etc/codex/skills` (admin), or bundled.
- Frontmatter: `name`, `description` required. An optional `agents/openai.yaml` sets display
  metadata, `policy.allow_implicit_invocation` (default `true`; set `false` to force explicit
  `$skill`/`/skills` invocation only), and `dependencies.tools` (required MCP servers).
- Discovery list (name+description only) is capped at ~2% of context / 8000 chars by default
  (configurable up to 10k tokens via `skills.max_context_tokens`) — too many skills means some get
  dropped or truncated, so skill count and description length both matter.
- `AGENTS.md` is a **separate**, always-loaded instruction channel, not gated by trigger-matching:
  Codex concatenates `~/.codex/AGENTS(.override).md` with every `AGENTS.md` from repo root down to
  cwd (closer file wins on conflict, 32 KiB cap). This is the bootstrap hook for Codex.

**Cursor**
- Officially supports Agent Skills now: folder with `SKILL.md`, auto-discovered at startup from
  `.agents/skills/` (same path Codex uses), `.cursor/skills/` (project), `~/.cursor/skills/`
  (personal) — and, for cross-tool compatibility, Cursor *also* reads `.claude/skills/` and
  `.codex/skills/` directly.
- Unlike Claude Code, Cursor walks the skills root **recursively**, so nested folders are fine.
- Invocation: automatic by context match, or manual via `/` + skill name in Agent chat.
- Separately, `.cursor/rules/*.mdc` (`alwaysApply: true` or `description`/`globs`-gated) and
  `AGENTS.md` are supported for always-loaded or glob-scoped instructions — `AGENTS.md` is Cursor's
  bootstrap hook too, same file Codex reads.

**What this means for packaging**
- `.agents/skills/<name>/SKILL.md` is read natively by both Codex and Cursor — ship the canonical
  copy there. Claude Code does not read that path, so it still needs its own copy/symlink at
  `.claude/skills/<name>/SKILL.md`. No `agents/openai.yaml`-equivalent is needed for Cursor; the
  Codex one is harmless extra metadata Cursor ignores.
- The "each skill ends with an instruction to read and follow the next skill file directly"
  chaining mechanism (above) holds up on all three — it's just a Read-and-follow instruction, not a
  platform-specific invoke call.
- **Stronger bootstrap for Resume/Audit routing than relying on description-matching alone:** all
  three platforms have an always-loaded, non-probabilistic file — `CLAUDE.md` (Claude Code),
  `AGENTS.md` (Codex, Cursor). Each should carry one short pointer: "before starting work, check
  for `.athene/state.md`; if present, follow Athene: Resume; if absent and the request is about
  building something, follow Athene: Audit first." This removes the risk of the router skill simply
  not being auto-triggered because its description didn't match closely enough.
- Skill `description` fields are the single highest-leverage thing to get right on every
  platform — they are what's always in context and what every auto-invocation decision rests on.

## Suggested build order (for the upcoming phase-wise plan)

1. Repo scaffold + state-file schema (unblocks everything else being testable).
2. Athene: Resume + Athene: Audit (so state-tracking exists before build-phase skills rely on it).
3. Governance-artifact generation (fixed baseline first, then variable layer) inside Athene
   (build), since PR/issue/review rules are needed before the review-gate behavior can be tested.
4. Stack-decision flow (options table, free/paid/tier question, MCP/connector detection) inside
   Athene (build).
5. Curated source-index file + self-growing fetch behavior.
6. Chaining: Discovery → Athene (build) → Launch handoff instructions, tested end-to-end.
7. Cursor packaging, then Codex `agents/openai.yaml` fleshing-out, last — once behavior is proven
   on one platform.
