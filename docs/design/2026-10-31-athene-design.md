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

## Skills (7) and the flow

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
   - **Engineering quality bar (veteran-engineer posture):** every nontrivial build decision gets
     pressure-tested the way a senior engineer would, not just matched against the curated source
     file above. See the dedicated researched section below for the full checklist (non-functional
     requirements, security, latency, server management, edge cases, review discipline) and how it
     plugs into this skill's decision flow and the review/merge gate below. Scope note: this lives
     in skill 2 (new builds), not Athene: Audit — Audit stays scoped to retrofitting process/
     governance on existing repos (see Audit's section), it does not review existing code quality.
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
       `attribution.commit`/`attribution.pr` to empty strings (and `attribution.sessionUrl: false`
       where session links are also prohibited) in the repo's own `.claude/settings.json` so the
       trailer is suppressed at the tool level, not just by instruction — `includeCoAuthoredBy` is
       deprecated and is ignored once either attribution key is already set, so it isn't reliable
       for this; Codex and Cursor have no equivalent setting, so for those the no-attribution rule
       lives purely in this governance doc and the skill's own commit/PR instructions.
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

6. **Athene: Code Health** (new, added 2026-11-02 — see "Code-quality audit" below) — distinct
   from Athene: Audit. Audit retrofits *process* (governance docs, ownership, CI) onto a repo;
   Code Health reviews the *code itself* — bugs, security, scale, missing tests, speed, lean —
   and ranks findings most-important-first. One-shot report, changes nothing. User-invoked
   (`/athene-code-health` or similar), not part of the Discovery → Build → Launch chain — doesn't
   hand off to or from any other skill.

7. **Athene: PR Review** (new, added 2026-11-06 — see issue #85) — distinct from both Code
   Health and from `athene`'s own pre-PR self-review subagent pass. Code Health reviews the whole
   repo, one-shot, with no GitHub awareness; the self-review pass runs *before* a PR exists, on a
   diff Athene is about to send for human review. This skill runs against a PR that's already
   open on GitHub — someone else's, or the user's own — reviews only its diff, and posts the
   findings as a disclosed PR comment via `gh pr comment`. Fetches candidates with
   `gh pr list --author @me` and `gh pr list --search "review-requested:@me"`, lets the user pick
   one PR per run (not a batch sweep), and dispatches a subagent to do the actual diff read and
   review so the full diff plus traced flow never lands in the main thread doing the PR-picking
   work. Reuses Code Health's six finding categories, adapted to diff scope, but reports them in
   a compact `file:line: severity: problem. fix.` inline format instead of Code Health's
   narrative block — posted as a general PR conversation comment (`gh pr comment`, not an
   inline diff comment), but still meant to be scanned finding-by-finding next to the PR's own
   diff view, not read top-to-bottom like a standalone report. User-invoked, one-shot, no
   handoff to or from any other skill, same as Code Health.

## Persistent state

All three build-phase skills (Discovery, Athene build, Launch) write/update a state file in the
repo as they progress — current phase, decisions made, open questions, which skill is active.
Exact location/format (e.g. `.athene/state.md`) is left to the builder; constraint is that it must
be readable by Resume and Audit, and should not block normal repo tooling (likely committed, plain
markdown, not gitignored, so it survives across machines/agents/sessions).

## Discovery brief / Launch plan storage (decided 2026-11-05)

Distinct from `.athene/state.md` above (always committed, inside the target repo): the actual
product brief Discovery produces and the launch plan Launch produces had no defined storage
location in either skill's draft — only the *decision* to approve them gets recorded in
`.athene/state.md`, never the document itself.

Compared two real patterns before deciding: `superpowers:brainstorming` commits its design docs
*inside* the target repo at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, versioned and
visible to every collaborator. gstack's `/spec` skill instead archives specs *outside* the repo,
in a local per-machine state root (`$GSTACK_STATE_ROOT/projects/<slug>/specs/<timestamp>-
<slug>.md`), uncommitted and not synced anywhere unless the user opts in via `--sync-archive` —
the GitHub issue it files is the shared/durable artifact; the local file is just the agent's own
copy.

**Decision: follow gstack's pattern, not superpowers'.** Write the brief/plan to a local,
per-machine directory outside the target repo's git tree — `~/.athene/<repo-slug>/briefs/
<timestamp>-<topic-slug>.md` for Discovery, `~/.athene/<repo-slug>/launch-plans/<timestamp>-
<topic-slug>.md` for Launch. Not committed, not synced anywhere. `.athene/state.md`'s Decisions
made records only the decision and this file's path, not the brief's full content — same
"durable record is small, full detail lives in the local copy" split gstack uses, minus gstack's
issue-filing step (Discovery hands off straight to `athene`; there's no GitHub issue per brief
here), so the path in Decisions made is the only pointer that exists. Known, accepted limitation
carried over from gstack's own: losing the local file loses the brief's full detail — acceptable
here since the decisions that matter are already captured in `.athene/state.md` regardless.

`<repo-slug>` derivation (folder name, or a hash if collisions matter) is left to the builder —
not solving a problem that hasn't shown up yet. **Done** (#67): wired into both
`athene-product-discovery`'s "Produce the handoff" and `athene-launch`'s "Build the launch plan"
sections.

## Issue and PR conventions (for this repo's own build, researched 2026-10-31)

Standard across most open-source repos, and used for Athene's own build issues from Phase 0 on:

- **Title:** same type prefix as the Conventional Commits baseline (`feat/fix/chore/docs/refactor/
  test/perf/ci/build`) plus a scope, e.g. `chore(state): define .athene/state.md schema`. Keeps
  issue titles and the commits that close them readable as one vocabulary.
- **Body:** four sections — **Context** (what and why, one or two sentences), **Tasks** (a
  `- [ ]` checklist; GitHub renders it as progress and one issue should cover one coherent piece of
  work, not several), **Acceptance criteria** (specific, observable, testable — not "write good
  code"), **Depends on** (links to issues that must land first, or "none").
- **Every `- [ ]` checklist item stays one line (found 2026-11-06, #84/#85).** GitHub renders a
  top-level `- [ ]` item as a tracked-task row with a drag handle and an overflow menu reserved on
  the right, regardless of how much text the item holds. A multi-line item (a long task description
  that wraps) leaves that reserved space sitting empty next to a short first line — looks like a
  rendering bug, isn't one; it's GitHub's own fixed-width chrome for that row. Fix is content, not
  markdown syntax: keep each item to one concrete action on one line; move anything needing more
  explanation up into Context or Proposal and leave the checklist item as a short pointer back to
  it. Now documented in both `CONTRIBUTING.md` templates' "Issue/PR checklist items stay one line"
  section — the same rule this repo's own issues follow (per "this is the same shape the
  fixed-baseline issue templates generate" above) applies to Athene's own build issues too.
- **Write Context/Proposal/Acceptance-criteria paragraphs as one unbroken line too (found
  2026-11-06, #84/#89, separate root cause from the checklist-item fix above).** GitHub renders a
  single newline inside an issue/PR body as an actual line break — unlike a `.md` file committed to
  the repo, where a soft newline inside a paragraph just collapses into a space when rendered.
  Hand-wrapping prose at ~70-80 characters, a habit that makes a `.md` file or a terminal heredoc
  readable in a source editor, instead produces a wall of short, forced lines on GitHub's rendered
  issue/PR view: a gap on the right of each line and the next sentence appearing to start on a new
  line even when it's a direct continuation of the one above it. Looked like the same symptom as
  the checklist-item gap at a glance, but it's a different cause and hits every paragraph in a body,
  not just `- [ ]` items — don't fold the two fixes together. Now documented alongside the
  checklist-item rule in both `CONTRIBUTING.md` templates, as its own "Write issue/PR paragraphs as
  one line, let the browser wrap them" section.
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

## Tags, releases, packages, and deployment environments (researched 2026-10-31)

Feeds the "release/tag policy doc" already named in the governance variable layer above and the
still-open risk-tier → governance-doc-set mapping table (see Left to the builder).

- **Tag ≠ release ≠ package — three different layers:**
  - A **tag** is a fixed marker on one commit. Cheap, no notes, no assets. Use SemVer
    (`vMAJOR.MINOR.PATCH`, pre-release suffix `-beta.N`/`-rc.N` where needed) — never ad hoc names
    like `release-1` or `final-version`.
  - A **release** sits on top of a tag and adds release notes, doc links, and downloadable assets —
    this is the user-facing layer.
  - A **package** (GitHub Packages / GHCR) is the built artifact itself (library, container image),
    published by a workflow. Tag and package version are not guaranteed to match unless a workflow
    enforces it — don't assume they stay in sync without that.
  - Practical pattern: push an annotated SemVer tag → a workflow triggered on `v*` tags creates the
    release and publishes the package. One tag push, not three manual steps.
- **When each is worth it, by risk tier (informs the still-open mapping table):**
  - Solo/fun project: tags only, if even that — no release notes, no package registry. Skip the
    whole layer by default.
  - Opensource/startup project: full chain — SemVer tags, releases with notes, packages published
    via CI on tag push. This is what the existing "release/tag policy doc" variable-layer item
    should generate for this tier.
- **Packages via GitHub Actions:** publish from CI using the built-in `GITHUB_TOKEN`, not a
  personal access token, for any registry that supports repo-scoped permissions — only fall back to
  a PAT where the registry doesn't support that.
- **Deployment environments** (GitHub Actions `environments`, separate from tags/releases/packages):
  relevant only once Athene or a target repo actually deploys somewhere, not for a library/skill
  repo like this one.
  - Required reviewers gate a job behind manual approval before it runs — use for production
    deploys specifically, not every environment.
  - Environment secrets are scoped to the environment and withheld until a required reviewer
    approves — this is how production credentials stay behind the approval gate, not just
    documented policy.
  - Admins bypass protection rules by default; disable that bypass for any environment meant to be
    a real gate, not just a discipline-only step.
  - Self-hosted runners aren't isolated by environment protection — don't treat environment rules as
    a security boundary on self-hosted infra.

## Engineering quality bar: veteran-engineer posture (researched 2026-10-31)

Answers a scope question raised during Phase 0 build: does Athene review code quality and system
design, or only repo process? Answer as designed: **process is Audit's job; engineering quality is
skill 2's job**, exercised at each nontrivial build decision, not as a retroactive code audit. This
section is the research backing that bar — not yet broken into a build issue; folds into skill 2's
existing "Evidence-backed architecture" and "review/merge gate" bullets above when that phase is
scoped.

**Questioning requirements before building (ADR-style decision flow):**
- For any decision a future engineer would reasonably ask "why was this done this way," write it
  down: problem/constraints/requirements → options considered with tradeoffs → decision →
  consequences → when to revisit. A short note, not an essay.
- State requirements as measurable targets, not vague goals — "feed renders in under 200ms," not
  "should be fast." Decisions get cited against these targets, not vibes.
- Check reversibility before deliberating hard: a choice changeable in under a week of work doesn't
  need the full ADR treatment — decide fast, don't stall on low-stakes choices waiting for perfect
  information.

**Non-functional requirements, narrowed and quantified per system (not a universal checklist):**
Pick the 3-5 that actually matter for *this* system and put a number on each:
- Scalability — expected traffic, and whether it's bursty (time-of-day, event-driven spikes).
- Consistency vs. availability (CAP tradeoff) — which one this system gives up, and why, for this
  specific data path.
- Latency — a budget in ms for each critical path, not an overall "fast" goal.
- Fault tolerance — timeouts, retries, and backoff on every call across a trust boundary; these
  three are the standard toolkit for distributed-system resilience.
- Durability, and compliance/data-protection where the domain requires it.
- These requirements compete — e.g. meeting functional requirements is usually the easy part;
  scalability and low latency simultaneously is where tradeoffs actually bite. Name the tradeoff
  being accepted, don't pretend all of them are free.

**Security — threat-model at design time, not after:**
- Threat modeling happens during design, before the first line of code, not as a post-hoc review.
- Baseline secure-coding checklist (OWASP): define security requirements up front, validate all
  inputs, enforce access control, use vetted security libraries/frameworks over hand-rolled crypto
  or auth, implement security logging and monitoring.
- Specific known risks to check for: injection (SQL/XSS/command), broken auth, software/dependency
  supply-chain integrity (checksums/signatures on updates and dependencies), rate limiting on auth
  endpoints, MFA on privileged accounts.

**Latency and performance:**
- Set the latency budget per critical path at design time, before writing code against it.
- Standard levers: caching + CDN for read-heavy paths (also reduces origin load and blast radius of
  regional outages), async/queueing to decouple slow work off the critical path, batching to avoid
  N+1 query patterns.
- Don't over-optimize ahead of evidence — justify performance work with a measured number, not
  guesswork; premature optimization that complicates code for no measured gain is a net loss.

**Server management and operations (SRE posture):**
- Define SLOs/SLIs per service before launch, not after an incident forces the question.
- Observability from day one: the three pillars (metrics, logs, traces), wired in as the system is
  built, not bolted on retroactively once something breaks.
- Capacity planning from historical/measured data, revisited on a regular cadence — not a one-time
  guess at launch.
- Automate deployment and incident response where the project's risk tier justifies the investment
  (ties into the variable governance layer above); run blameless postmortems when something breaks.

**Edge cases and review discipline:**
- Review checklist, not ad hoc reading — checklist-driven review measurably catches more defects
  than unstructured review (a cited SmartBear study across 2,500 reviews found 36% more defects
  caught with a checklist).
- Explicitly probe: empty/null inputs, boundary conditions, maximum sizes, concurrent access — not
  just the happy path. Tests must cover failure paths, not only success, or they give false
  confidence.
- Tier findings by severity: security, data loss, and crash bugs block merge; style nits are a
  linter's job, not a reviewer's — don't spend review time there.

**Where this plugs into the existing design:**
- Extends skill 2's "Evidence-backed architecture" bullet above: the curated source file is one
  input, this checklist is the other — both inform the same per-decision tradeoff table shown to
  the user.
- Extends the "review/merge gate" bullet above: the self-review subagent pass should check this
  checklist (non-functional targets, security, edge cases), not just functional correctness.
- New "Left to the builder" item: the concrete question set/template Athene asks at each
  architecture decision point to operationalize this checklist, and how the review-gate subagent's
  prompt encodes it.

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

## Reference-copy duplication: the problem, and how to reduce it (researched 2026-11-02)

**The problem, concretely.** Every skill is mirrored wholesale into `.agents/skills/` and
`.claude/skills/` by `scripts/mirror-skills.sh` — that layer is already a proper generator, not a
duplication risk, since it's automated and nothing ever hand-edits the mirrored copies. The real
duplication is one layer up: `skills/athene-audit/references/*.md` and
`skills/athene-audit/templates/set-review-gate.sh` are bundled copies of `docs/*.md` and
`scripts/set-review-gate.sh` (made because a skill needs to be self-contained once mirrored
elsewhere — the source repo's own `docs/` folder doesn't travel with it). Those bundled copies
were kept in sync by hand (`cp` run manually after editing the source), not by any automated
step. This caused real bugs during #19/#22's review: the bundled
`governance-doc-set-mapping.md`/`review-gate.md` copies kept saying "not yet wired into Audit"
after the source files were updated to say they were, and `athene-audit/SKILL.md` separately
restated the risk-tier criteria from `governance-doc-set-mapping.md` in its own words, creating a
second copy that could (and did almost) drift from the table it was paraphrasing.

**Researched pattern: single source + include-directive expansion at build time.** Established
docs-as-code practice (e.g. the docs-ssot project's `<!-- @include: path -->` resolver, DocFX's
remote-include extension) is: content exists in exactly one canonical file; anything that needs
it elsewhere holds an include marker, not a copy; a build step resolves markers into the real
content; the resolved output is clearly generated and never hand-edited (the same convention this
repo already follows for `.agents/skills/`/`.claude/skills/` — a generated file that gets silently
hand-patched just desyncs again on the next generation run).

**Applying it here:** extend `scripts/mirror-skills.sh` to expand a simple
`<!-- include: path/to/docs/file.md -->` marker before copying a skill's files into
`.agents/skills/`/`.claude/skills/`. `skills/athene-audit/references/*.md` and
`templates/set-review-gate.sh` become one-line include-marker stubs instead of literal copies —
`docs/*.md` and `scripts/set-review-gate.sh` stay the only place the actual content is written.
**Done** — implemented in #25/#26.

## Prior-art review: `DietrichGebert/ponytail` (researched 2026-11-02)

Cloned and read before starting the `athene` build skill — a mature, published multi-agent skill
repo (same "lazy senior dev" persona active in this session). Findings and the decisions made
from them:

1. **Code-quality audit — closes a real gap.** `skills/ponytail-audit/SKILL.md` reviews a whole
   repo for bugs, security holes, scale limits, missing tests, slow paths, and bloat — ranked
   most-important-first, each finding with four parts (what it is / problem / fix / what happens
   if skipped). Athene had nothing like this: Athene: Audit only retrofits *process* (governance
   docs, ownership, CI), never the code itself — a gap flagged earlier in this project's own
   history and now closed by adding **Athene: Code Health** as skill 6 (see above). Scope
   borrowed directly from ponytail's structure: map first (entry points, data flow, expected
   load) → find in ranked categories → 4-part findings, capped at 20 → verdict line.
2. **`shortcut:` comment + debt-ledger convention.** Ponytail marks every deliberate
   simplification with `shortcut: <ceiling>, <upgrade path>` and a `/ponytail-debt` command greps
   the repo into a ledger, flagging any marker with no upgrade trigger as rot risk. Athene has
   been doing this by hand all through its own build (hand-written "Known limitation" sections in
   this very doc and others) with no systematic convention. Adopting the same marker convention
   for Athene's own build going forward, and for code Athene writes in target repos — tracked as
   a build-order item below. Athene's marker word: `athene:` (parallel to ponytail's own), to stay
   distinguishable in a repo that might use both skills.
3. **Compact bootstrap snippet should carry real content, not just route.** Ponytail's `AGENTS.md`
   is a condensed copy of the *actual ruleset* `SKILL.md` carries, so a platform that never loads
   the full skill still gets real behavior. Athene's current bootstrap snippets
   (`docs/templates/claude-md-snippet.md`/`agents-md-snippet.md`) are pure routing pointers ("check
   `.athene/state.md`, go to Resume/Audit") — they carry none of the engineering-quality-bar
   checklist. Decision: expand them to also carry a condensed version of that checklist, so it
   applies even on a session that never triggers full-skill loading via description-matching.
   Tracked below.
4. **Invariant-phrase drift-check — noted, not adopted now.** Ponytail's
   `scripts/check-rule-copies.js` doesn't byte-diff its ~7 near-duplicate rule-file copies across
   platforms; it asserts specific load-bearing phrases survive verbatim in each, because those
   copies are *compact adaptations* of the full prompt, not exact copies. Athene's own duplication
   problem (#25) was exact-copy, so the include-marker fix already in place is the right-sized
   tool for it — byte-identical, verified by diff. If Athene ever ships a short-vs-long variant
   (e.g. a condensed `AGENTS.md` ruleset per point 3 above, diverging in wording from the full
   skill body), this is the technique to reach for instead of trying to keep two different-length
   texts byte-identical. Not needed yet — noted for when it is.
5. **Measured benchmarking harness — deferred, real gap.** Ponytail ships a full benchmark suite
   (`benchmarks/`) comparing the same agent with and without the skill across repeated runs:
   lines of code, cost, time, tokens, test coverage — published numbers back every claim in its
   README. Athene has zero empirical validation that any of its process/governance overhead
   actually improves outcomes. Real gap, but building a benchmark harness needs the `athene`
   build skill to exist first (nothing to measure yet) — deferred until after that skill ships,
   not blocking it.
6. **Broader platform reach + marketplace distribution — deferred, lower priority.** Ponytail
   ships to ~20 agent hosts via npm and platform-native plugin marketplaces; Athene targets 3
   (Claude Code, Codex, Cursor) via a local `skills/` + mirror-script convention, with no external
   distribution channel at all yet. Lower priority than the above — Athene isn't close to being
   ready to ship externally, and the packaging convention (#1, #25) would need real rework to
   support compact per-platform adaptations (point 4) before broader reach is worth pursuing.

## Prior-art review: `unclebob/ub-mode` (researched 2026-11-03)

Single-file skill (~150 lines, no bundled tooling), structured as First Make it Work → Then Make
it Right → Practice. Most of it already exists in Athene, via existing lifecycle stages or the
`superpowers` skills this project already uses (TDD, root-cause-not-symptom fixes, refactor-pin-
behavior, commit/push discipline, context-window hygiene). One real gap, tracked below:

1. **Quantified code-quality checks — real gap, tracked as #43.** `ub-mode` pairs with three
   companion tool repos (`crapper`, `dryer`, `mutator`) to enforce numeric thresholds: CRAP score
   `< 10` per function (cyclomatic complexity + coverage-weighted risk), minimum pairwise Jaccard
   structural-similarity score `>= 0.8` (Athene's proposed threshold — `dryer`'s own documented
   default is `0.82`; this isn't a whole-project duplication ratio) flagged for elimination, and
   mutation testing to surface undertested code and dead code beyond what line coverage shows —
   no numeric pass threshold proposed for this one, report results rather than gate on a number
   until one is chosen. **`athene-code-health`** is Athene's equivalent surface (ranked
   bugs/security/scale/missing-test/speed/lean audit) but is qualitative only — no numeric checks
   anywhere in it. Decision: add these checks to Code Health, guidance-only — detect and run an
   existing project tool that already computes one of these dimensions where present, report the
   gap rather than silently skipping it where absent, don't bundle `crapper`/`dryer`/`mutator`
   themselves (general-purpose but not confirmed across every stack Athene might touch).
2. **"Keep a Log" and "Attack the Premise" — noted, not adopted now.** `ub-mode`'s per-action log
   (every action + the reason, reported on completion) is finer-grained than `.athene/state.md`'s
   Decisions made, which records decisions, not every action — a real distinction, but not clearly
   worth the verbosity cost for every skill's every run; revisit if a real debugging need for a
   finer trail shows up. `ub-mode`'s "Attack the Premise" (when two independent fixes hit the same
   gate, stop and name the shared premise in one sentence before trying a third fix) is a sharp
   debugging heuristic, but belongs in a debugging skill, not Athene's governance/build scope —
   `superpowers:systematic-debugging` is the right home for it if ever adopted, not this project.

## Behavioral continuity across sessions (researched 2026-11-03)

**The problem.** A fresh session in a repo the user has already been working in shouldn't feel
like starting over — but actually *continuing* the old session (replaying its context) burns
tokens and context for no good reason. The goal is behavioral continuity on a cheap new session,
not context carryover. This is distinct from `.athene/state.md` (that's project task state —
*what* was decided) and purely about *how* the AI behaves: pace, autonomy, what it does without
being asked again, matching the pattern already established in this repo. Entirely behind the
scenes — it changes default AI behavior at session start, never adds a user-facing step, a
question to answer, or a workflow change. If it's not working silently, it's not working.

**Two scopes, both needed (per the earlier memory-taxonomy research above):**
- **User-level (cross-repo):** how this person works regardless of project — pace, autonomy
  preference, risk tolerance, how they like to be asked things. New territory for Athene — lives
  outside any single repo, unlike everything built so far.
- **Repo-level:** the working rhythm actually established *in this specific repo* — e.g. this
  user always checks `git status` and open issues before touching code in this repo, or always
  wants fixes verified by actually running them before committing. Derived from this repo's own
  session history, not carried from other projects.

**How it's learned — signal-triggered, not blanket summarization (Reflexion, 2023; matches this
session's own `feedback`-memory trigger rule already in use):** write a reflection only on a
crisp signal — a correction, an explicit confirmation of something non-obvious, or a repeated
friction point (the user had to re-ask or redo a step). Never on an end-of-session timer, and
never by stopping to ask "should I remember this?" — that's the ceremony pattern the research
flags as the wrong design. Background, non-blocking, silent when there's nothing worth keeping.

**Trust boundary, non-negotiable:** only ever promote the *user's own* signal — their correction,
their confirmation — never anything encountered incidentally during the session (a fetched page,
another contributor's PR, an issue someone else filed). Passive capture that doesn't enforce this
is a documented poisoning vector for long-term memory. Explicit instructions and governance
*always* outrank an inferred pattern — an inferred "this user usually skips review" must never
override an actually-requested gate.

**Cold start — Claude Code only, v1:** Claude Code writes raw session transcripts to
`~/.claude/projects/<encoded-path>/<session-id>.jsonl` (confirmed, one file per session, 30-day
default retention) — a real, accessible format a setup step could scan once to seed a rough
starting profile, cheaper than starting from nothing (ponytail's own `/ponytail band import`
already reads this same format for a different purpose — real precedent it works). Codex and
Cursor don't have a confirmed equivalent researched yet. **Decision: gate this whole feature to
Claude Code for v1, not just the cold-start seed — revisit Codex/Cursor once a way to read their
session data (or some other mechanism) is found.** Without the history-seed, a Codex/Cursor
session would otherwise just start the incremental signal-triggered building from empty — but
until a platform-appropriate mechanism exists at all, the simpler call is not shipping a
half-working version there.

**Where this plugs in:** closest existing home is Athene: Resume — it already runs at session
start and already reads repo state; this would be an additional silent read alongside
`.athene/state.md`, not a new user-facing step. Not yet scoped into a build issue — this section
is the research and the decision record, per the user's explicit ask to research further before
turning it into one.

## Prior-art review: product-discovery agent skills (researched 2026-11-04)

Skill 1 (Athene: Product Discovery) already exists as a standalone draft (see "Intent and why"
above) and has a feature list recorded from it plus the design doc's own additions, but hadn't
been checked against other AI-agent product-discovery skills before scoping a build issue, per
the user's explicit ask. Reviewed three real repos in this space, same depth as the ponytail/
ub-mode reviews above:

1. **`phuryn/pm-skills`'s `opportunity-solution-tree` skill — real gap, worth adopting.** Teresa
   Torres' Opportunity Solution Tree (OST): a 4-level structure connecting a single measurable
   **outcome** → 3-7 customer **opportunities** (framed as "I struggle to..."/"I wish I could...",
   never as features) → 3+ **solutions** per opportunity (compare multiple before picking one,
   avoid the first-idea trap) → 1-2 **experiments** per solution (hypothesis, method, metric,
   success threshold). Opportunities get ranked by an **Opportunity Score** (Dan Olsen's formula,
   `Importance × (1 − Satisfaction)`, both normalized 0-1) when the conversation has evidence to
   support both inputs; otherwise use a qualitative ranking and record the evidence gap rather
   than inventing normalized numbers from an interview-only conversation. Athene's own
   draft's "Generate and choose options" section already does the solutions-comparison part (2-3
   genuinely different approaches, smallest disproving test) but has no explicit outcome →
   opportunity → solution → experiment structure above it, and no prioritization formula for
   *which opportunity* to spend that comparison on in the first place — it jumps straight to
   comparing solutions. Adopting the OST shape would mean: before "Generate and choose options"
   runs, first map the outcome (from the framing/success-signal work already in "Discover the
   intent") to a short, scored list of opportunities, and only then generate/compare solutions for
   the top 1-2 — closes a real sequencing gap, not a new feature.
2. **`ncklrs/startup-os-skills`'s `product-discovery` skill — explicit
   anti-pattern list, worth adopting.** It names a recurring set of discovery failure modes:
   solution-first discovery (falling for a solution before the problem's validated — Athene's
   draft's product-quality checks implicitly guards this but never names it), leading the witness,
   confirmation bias, sample-of-one (deciding from one interview/one user), proxy research (asking
   salespeople/support instead of the actual user), feature-requests-as-research (users ask for
   features, not problems — Athene's "Discover the intent" section already distinguishes stated
   facts from assumptions but doesn't call this specific trap out), analysis paralysis, and
   HiPPO-driven decisions (highest-paid-person's-opinion overriding evidence). Athene's
   `product-brainstorming`-style skills (see this repo's own available-skills list) already carry
   an equivalent anti-pattern list for brainstorming generally; Discovery doesn't have its own
   discovery-specific one. Worth a short, named list in the "Discover the intent" or
   "Product-quality checks" section — a known trap named once is cheaper than re-discovering it
   per session.
3. **`ncklrs/startup-os-skills`'s research-method-selection matrix — noted, not adopted as a new
   structure.** Classifies methods as generative (interviews, contextual inquiry, diary studies —
   discover unknown unknowns), evaluative (usability/A-B/prototype testing — validate known
   hypotheses), or quantitative (surveys, analytics, card sorting — measure and prioritize), each
   mapped to an interview-type/question pairing. Athene's draft already proposes "the narrow
   research question and source scope" before running research, which covers the same decision
   point in fewer words — the three-tier taxonomy is good reference material but restating it as
   a new required step would just be the same instruction with more ceremony. Not adopted as new
   structure; the underlying method list is useful context if the question ever comes up of which
   research method to propose.
4. **Jobs-to-be-Done's functional/emotional/social/context split — noted, already implicit.**
   Both repos (and the `product-brainstorming` skill already available in this environment)
   name JTBD's distinction between the functional job (what the user does), and the often-more-
   powerful emotional/social jobs (how they want to feel, be seen) and situational context
   (when/where). Athene's draft already asks about "problem/job" and "desired outcome" without
   naming this specific breakdown. Not a new feature — worth keeping in mind as a deeper probe
   when a stated problem feels thin, not a new mandatory question.
5. **Continuous-discovery weekly/monthly/quarterly cadence — explicitly rejected, wrong shape for
   this skill.** Several of these repos (and Teresa Torres' own framework) assume discovery is an
   ongoing weekly practice across a product's whole life, not a one-shot brief-then-handoff flow.
   Athene's Discovery skill produces one approved brief and hands off to `athene` (build) — a
   discrete flow, not a recurring cadence skill. Adopting a cadence structure here would be
   building the wrong shape of skill; rejected, not deferred.

Repos reviewed: [phuryn/pm-skills](https://github.com/phuryn/pm-skills) (skill:
`pm-product-discovery/skills/opportunity-solution-tree`), [ncklrs/startup-os-skills](https://github.com/ncklrs/startup-os-skills)
(skill: `skills/product-discovery`), plus a broader landscape search (BuildBetter's `bb-skills`,
`product-on-purpose/pm-skills`, `wdavidturner/product-skills`, `popup-studio-ai/bkit-claude-code`)
confirming this is a crowded, fragmented space with no single dominant standard — the two gaps
above were the concrete, adoptable findings, not a reason to rebuild Discovery around any one
repo's full structure.

## External-repo personas: guest contributor and contribution-receiving maintainer (researched 2026-11-04)

**The gap.** Every Athene skill so far assumes the current repo is the one Athene governs — it
writes its own baseline (Conventional Commits, `athene:` markers, no-AI-attribution) *into* the
target repo. Two real personas fall outside that assumption and have no coverage anywhere today:

1. **Guest contributor** — the user asks Athene to fix something in, or send a PR to, a repo
   Athene doesn't own or govern (someone else's open-source project). Imposing Athene's own
   baseline there is wrong; the target repo's existing rules govern, not Athene's.
2. **Contribution-receiving maintainer** — the user owns a repo Athene governs, but it also takes
   outside PRs. The "PR intake" lifecycle stage (see "Skills (6) and the flow" above) already
   says non-trivial external work needs an accepted issue or a named sponsor, but says nothing
   about DCO/CLA checks, first-time-contributor routing, or whether the repo even has a stated
   policy on AI-authored contributions — a live, consequential gap, not a hypothetical one (see
   below).

**What open-source practice actually expects of a guest contributor** (general web research,
2026-11-04 — individual project pages, not a single authoritative standard; verify against the
specific target repo before relying on any of this):
- **Read and defer to the target's own `CONTRIBUTING.md`, commit-message style, and DCO/CLA
  requirement** — never impose Athene's Conventional Commits/`athene:`-marker baseline on a repo
  Athene doesn't govern. DCO sign-off is a `git commit -s` trailer, distinct from a CLA (a
  one-time, broader legal agreement some projects require before any code is accepted) — the two
  aren't interchangeable, and some projects run an automated bot that determines which (if either)
  applies and walks the contributor through it.
- **Discuss first for anything non-trivial.** Check open and recently merged PRs/issues for
  duplicate work before starting. Open or claim an issue before sending a non-trivial PR or
  feature; several projects explicitly ask for this so a rejected approach doesn't waste a
  contributor's time. A trivial, obviously-correct bug fix is the exception most projects still
  accept directly as a PR.
- **Keep the diff focused** — no incidental reformatting of code the fix doesn't touch; makes
  review harder and is a named complaint in more than one CONTRIBUTING guide reviewed.
- **Run the target's own build/test/lint before submitting**, not just Athene's own quality bar —
  don't shift that burden onto the maintainer's CI.
- **Fill in the PR template the target repo provides** and stay responsive to review comments
  rather than treating the PR as done at submission.
- Sources (general web research, not project-specific; re-verify per target repo): CONTRIBUTING
  guides reviewed for [data-prepper](https://github.com/dlvenable/data-prepper/blob/main/CONTRIBUTING.md),
  [dashboards-search-relevance](https://github.com/opensearch-project/dashboards-search-relevance/blob/main/CONTRIBUTING.md),
  a pre-submission checklist skill at [tessl.io](https://tessl.io/registry/tessl-labs/good-oss-citizen/1.1.12/files/skills/preflight/SKILL.md).

**What open-source practice expects on the maintainer side** (same caveat — illustrative, not a
single standard):
- **DCO/CLA check belongs at triage**, not left implicit — Moby/Docker's own maintainer docs
  describe checking DCO sign-off as part of the initial label-based triage step, and closing
  stale, unresponsive PRs that never got one.
- **A CLA bot, where a CLA is required**, decorates the PR with a status check or comment and
  walks the contributor through it rather than making the maintainer explain it by hand each time
  (e.g. Microsoft's PyRIT project).
- **Code of conduct** is a named, linked document most serious projects adopt (often inherited,
  e.g. the Microsoft or Contributor Covenant one) rather than invented per-repo.
- **Newcomer routing** via a `good first issue` (and sometimes `first-timers-only` or
  `help wanted`) label, with a stated norm for claiming one (comment and wait to be assigned, or
  just open the PR directly — projects differ, so the maintainer's own CONTRIBUTING.md has to say
  which).
- **A stated stale-PR policy** — e.g. check in with the author first, reassign after a fixed
  window (PyRIT uses 14 days) if there's no response.
- Sources: Moby/Docker `MAINTAINERS`-flow docs, Microsoft PyRIT's
  [contributing guide](https://microsoft.github.io/PyRIT/latest/contributing/readme), the
  [oss-governance-bot](https://github.com/BirthdayResearch/oss-governance-bot) project (slash-command
  policy automation, contributor-type-aware).

**The real, live tension this surfaces: AI-disclosure vs. Athene's own no-AI-attribution rule.**
Athene's existing fixed baseline (see "Issue and PR conventions" above and
`skills/athene-audit/templates/CONTRIBUTING.md`) strips AI attribution from every commit/PR it
writes, by design — written before this research, for repos Athene itself governs, where the
owner wants that. Current reporting on AI-authored open-source contributions as of 2026-02 to
2026-06 shows the opposite is increasingly required or expected *by other projects' own rules*,
not Athene's call to make:
- **curl** started requiring AI-use disclosure in reports and PRs after a fabricated AI-generated
  vulnerability report wasted maintainer triage time.
- **Ghostty** required disclosure from 2025-08, then (2026-01) restricted AI-authored
  contributions entirely to pre-approved issues handled by existing maintainers.
- **tldraw** went further still (2026-01): auto-closes all external PRs, AI-authored or not.
- **GitHub itself** was reportedly weighing a PR "kill switch" for AI-generated submissions as of
  2026-02, after public maintainer pushback (Godot's maintainers specifically described
  AI-authored "slop" PRs as draining and demoralizing, and noted contributors often skip required
  disclosure anyway).
- RedMonk's own survey reportedly found dozens of open-source organizations split across outright
  bans, mandatory disclosure, and still-undecided policies — there is no single community norm to
  default to.
- Sources: [Socket.dev](https://socket.dev/blog/oss-maintainers-demand-ability-to-block-copilot-generated-issues-and-prs),
  [The Register](https://www.theregister.com/2026/02/18/godot_maintainers_struggle_with_draining/),
  [The Register](https://www.theregister.com/2026/02/03/github_kill_switch_pull_requests_ai),
  [DEV Community](https://dev.to/pickuma/why-open-source-maintainers-are-rejecting-ai-generated-pull-requests-12ac).

**Decision, guest-contributor direction:** when Athene is sending a PR to a repo it doesn't
govern, it must not apply its own no-AI-attribution convention there — that convention is scoped
to repos Athene governs, where the owner chose it. Instead: scan the target repo for a stated
AI-contribution policy first (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, PR template, pinned
issues, a bot-posted comment on a comparable prior PR) before writing any code, and branch on
what's found — ban/maintainers-only (don't open the PR, tell the user why), explicit
no-attribution with AI use allowed (follow that project's own no-attribution rule, don't disclose
— a stated "don't attribute AI" policy is a different case from an unstated one, and defaulting
to disclosure there would override a rule the target repo actually asked for), disclosure-required
(disclose per that project's own stated format, don't suppress it), or silent/unstated (default
to disclosing anyway in the PR description, since omission is the single most-cited maintainer
complaint in the research above — a disclosed AI contribution that's otherwise good work is a
minor issue; an undisclosed one that turns out to be wrong is a trust problem for every future
PR from the same account). Not yet a build issue — tracked below, since it needs its own scoping
pass (what exactly gets scanned for, where the policy-detection logic lives) before that.

**Decision, maintainer-receiving-contributions direction:** add a DCO/CLA-and-AI-contribution-
policy question to the same framing/risk-tier determination Athene already does (see
"Governance artifacts" in `skills/athene/SKILL.md` and `skills/athene-audit/SKILL.md`) — an
`opensource` framing should prompt a decision on all three (DCO, CLA, and the project's own
stance on AI-authored contributions), written into `CONTRIBUTING.md` explicitly rather than left
unstated, since "unstated" is itself now a documented source of maintainer friction. Also not yet
scoped into a build issue.

**Decision, Athene's own fixed baseline for `opensource`-framed repos:** `opensource` framing
forces AI-disclosure on every commit/PR Athene itself authors into that repo, overriding
`attribution.commit`/`attribution.pr` even if the user has set them to suppress attribution.
This is a real technical guarantee on Claude Code, where those keys are a tool-level setting
Athene itself writes; on Codex and Cursor, which have no equivalent attribution control at all
(see the fixed-baseline section above), it's a documented policy in `CONTRIBUTING.md` and the
skill's own commit/PR instructions, not an enforced one — same honesty gap the existing
no-attribution rule already has on those two platforms, not a new one this decision introduces.
`sessionUrl` is left alone by this override — disclosing AI authorship doesn't require also
publishing a session link, and changing a control the user set for an unrelated reason (session
privacy, not authorship disclosure) isn't this decision's call to make. Same reasoning as the
guest-contributor decision above: non-disclosure is the
single most-cited maintainer complaint in the AI-slop research, and an `opensource`-framed repo
by definition expects outside contributors and reviewers who didn't make that attribution choice
themselves. **This override must never be silent.** A version of this was considered where the
override wasn't disclosed anywhere, not even in the target repo's own README — rejected: it
would mean Athene secretly overriding its own operator's explicit setting and hiding that fact
from them specifically, not just from a bad actor (who'd just skip Athene's attribution path
entirely to slop a repo regardless — a silent flag only ever surprises the honest user who didn't
expect it, while doing nothing to stop someone determined to abuse it). Instead: write the
override into `CONTRIBUTING.md`'s "No AI attribution" section as a stated, conditional rule (off
by default, forced on for `opensource`), tell the user in the moment it fires, and record it in
`.athene/state.md`'s Decisions made like any other decision. Not yet scoped into a build issue —
same follow-up as the two decisions above, likely the same issue as the maintainer-receiving-
contributions one since both touch the same `CONTRIBUTING.md` "No AI attribution" section.

## Controlling AI-written comments (researched 2026-11-04)

**The gap.** Every lifecycle stage and quality-bar section built so far governs process,
architecture, and governance artifacts — none of it governs the comments Athene itself writes
into the code it produces. AI-written comments have a documented, specific failure mode distinct
from ordinary over-commenting: explaining the fix or change itself ("fixed the bug where X",
"updated to handle Y") rather than a durable property of the code. That kind of comment rots the
moment the next change touches the line and nobody updates it — the information belongs in the
commit message/PR description (timestamped history), not in code that outlives the fix it
describes.

**Canonical rule, confirmed across general sources, not AI-specific:** comments explain **why**,
never **what** — code already says what. Self-documenting code (naming, structure) is the first
line of defense, not a replacement for every comment, but a stale comment is worse than no
comment, so what remains should be durable and accurate, not a narration of the diff that
produced it.

**AI-specific evidence this is a real, measured gap, not just a vibe:**
- A 2026 readability study of LLM-generated code found redundant/restating comments as the
  second most common issue after excessive complexity — more common than in human-written code.
- A 2024 study found ~20% of GPT-4-generated Java method comments contained demonstrably
  inaccurate statements — confident but wrong, not just verbose.
- Documented practitioner pattern: agents add confident "design-intent" comments not actually
  grounded in the code; some developers now block LLM-written comments outright over this.
- Caveat: no 2025-2026 benchmark found specifically quantifying this for current frontier
  models — the hard numbers above are from 2023-2024-era models (CodeLlama, GPT-4, Copilot).
  Treat as directionally confirmed, not precisely quantified for current models.
- Sources: [arxiv 2605.13280](https://arxiv.org/pdf/2605.13280) (LLM readability issues),
  [arxiv 2406.14836](https://arxiv.org/html/2406.14836v1) (inaccurate LLM comments),
  [arxiv 2303.11455](https://arxiv.org/pdf/2303.11455) (Copilot/Codex bug study),
  [Ardalis — When to Comment](https://ardalis.com/when-to-comment-your-code/).

**Two real enforcement mechanisms exist — "control" doesn't have to mean LLM judgment alone,**
which a practitioner report found noisy and overwhelming when run in CI by itself:

1. **Deterministic rule layer, cheap and mechanical — real prior art, not hypothetical.**
   `grain-lint` (Python-specific; the pattern generalizes, the tool doesn't) flags:
   `OBVIOUS_COMMENT` (a comment that just restates the line below it, e.g. `# return result`
   above `return result` — auto-fixable), `RESTATED_DOCSTRING` (a docstring that only expands
   the function name into a sentence, no new information), `VAGUE_TODO` (a TODO with no concrete
   approach or reason named). Suppressible per-line, meant to run alongside normal linters, not
   replace them. **Known gap:** no equivalent found for JS/TS/Go/other stacks Athene might build
   in — this pattern is proven for Python only; other languages fall back to the layer below.
2. **Subagent self-review layer, for what the linter can't catch.** The `No Comments` Claude Code
   skill dispatches a subagent to challenge every surviving comment: a comment survives only with
   **proof** — a genuinely external constraint outside the team's control. A constraint the
   *project itself* controls gets converted into real enforcement (a type, a runtime assertion, a
   test, a CI lint rule) **before** the comment justifying it is deleted — replace the comment's
   job with something that actually enforces it, don't just delete and hope. A comment explaining
   a fix/change fails the proof test outright (it's not an external constraint) and should move
   to the commit message instead — this is where the specific pattern flagged above gets caught.
- Sources: [grain-lint on PyPI](https://pypi.org/project/grain-lint/),
  [No Comments skill](https://mcpmarket.com/tools/skills/no-comments).

**Decision.** Run both layers, cheap-first, matching Athene's own lean-first instinct elsewhere
in this doc: the deterministic layer where a language has one (Python today; flag the gap for
other stacks rather than silently skipping it), then fold the subagent-proof-test into the
self-review pass `athene`'s review/merge gate already runs (see "Governance artifacts" in
`skills/athene/SKILL.md`, #38) — one more thing that pass checks before a PR is sent, not a new
separate gate. **Done** (#55): wired into `athene`'s Implementation lifecycle stage (deterministic
layer + per-language gap flag) and its "Governance artifacts" self-review pass (proof-test).
Also catches slop already shipped via `athene-code-health`'s "Lean" category (#53), a separate,
already-done piece of this same research.

## Launch case studies and channel-selection method (researched 2026-11-04)

**Why.** Skill 3 (Athene: Launch) already existed as a standalone draft (see "Intent and why"
above), but its "Build the launch plan" section said to "select a few channels where the audience
exists" with no method for choosing, and cited no real launch outcomes to calibrate expectations
against. Researched before scoping a build issue, same pattern as Discovery's prior-art review.
**Core scaffold now built** (#61), Bullseye Framework done (#62), launch-day-spike/illustrative-
case-study findings below done (#63) — same split pattern as Discovery's #48-51, all landed.

**Real launch case studies, 2014-2016 era (still the most detailed, if dated):**
- **Product Hunt's own 2014 launch** — seeded the community with hand-picked early users
  *before* going public, since a community's early culture is very hard to change once set.
  Milestones at three distinct points: 400 users by the end of the public launch's first day,
  then 2,000 users 20 days after the earlier *private* launch (not 20 days after going public) —
  via manual, non-scalable tactics, not paid acquisition.
  Source: [Ryan Hoover — Product Hunt's first 2,000 users](https://www.ryanhoover.me/post/how-we-got-our-first-2-000-users-doing-things-that-dont-scale).
- **Happenstance (2016)** — a Product Hunt launch brought 1,200+ signups in 24h at ~50%
  conversion. A newsletter push to 400 existing users *before* that launch only got 17 upvotes —
  a warm list doesn't guarantee launch-day votes.
- **Dropbox** — the canonical product-led referral case. The reward itself is confirmed by
  Dropbox's own 2012 announcement: 250MB free storage per successful referral (both sides)
  originally, doubled to 500MB in that later, separate 2012 promotion — don't attribute the later
  amount to the earlier growth period. The commonly-cited 100k→4M-user figure (reportedly over
  ~15 months, through around early 2010) has **no primary Dropbox source found** — it traces back
  to Drew Houston's public talks per secondary accounts, not a linkable primary document; treat
  it as a widely-repeated but unverified figure, not a confirmed one. Sources:
  [Dropbox's own 2012 announcement](https://blog.dropbox.com/topics/company/dropbox-referrals-are-now-twice-as-nice)
  (reward amounts only), [Prefinery — Dropbox referral growth study](https://prefinery.com/blog/dropbox-referral-program-3900percent-growth-study/)
  (the 100k→4M figure, secondary, unverified against a primary source).
- **Airbnb** — two separate growth mechanisms, not one: a tool letting hosts auto-cross-post
  Airbnb listings to Craigslist (rode Craigslist's existing demand until Craigslist patched the
  integration — reported by multiple growth-hacking write-ups but with **no single confirmed
  primary source**, not a company disclosure), and, separately, a referral program offering up to
  $100 in combined credit ($25 for a guest referral, $75 for a host referral, confirmed by the
  Next Web source) — the $100 figure was never a Craigslist cross-posting incentive. Sources:
  [HackerNoon — How Airbnb Hacked Craigslist for Viral Growth](https://hackernoon.com/how-airbnb-hacked-craigslist-for-viral-growth-24l35eg)
  (Craigslist tactic, secondary, unverified against a primary source),
  [The Next Web — Airbnb's referral program](https://thenextweb.com/news/airbnbs-new-referral-program-could-double-its-member-base)
  (referral-credit figures only — don't use it to support the Craigslist claim).
- **Harry's** — a pre-launch referral waitlist collected 100k emails in one week, showing each
  signup their queue position, referral count, and unlocked rewards.
- These figures are self-reported by the companies or by secondary write-ups, not independently
  verified against primary disclosures beyond the two sources cited above — treat as directional.

**2025-2026 update — confirms some findings, revises others (general web research, 2026-11-04):**
- **Product Hunt benchmarks by category:** consumer apps typically get 500-1,500 signups from a
  good launch; B2B SaaS gets a few dozen to a few hundred. Source:
  [shno.co Product Hunt launch statistics 2026](https://www.shno.co/marketing-statistics/product-hunt-launch-statistics).
- **Early-conversion/rank divergence, not a revenue claim.** A spring-2026 report of five SaaS PH
  founders (four with complete datasets, self-reported, non-comparable conversion windows, one
  signup total that includes LinkedIn activity) found 7-day signups ranged ~71-450 (median ~115),
  and that rank didn't track early *paid conversion* specifically — this is directional, not a
  revenue study, and doesn't establish that founder audience is the sole converting factor or
  that Product Hunt distribution has no causal effect; treat "a founder's own audience matters
  more than platform rank" as a hypothesis the data is consistent with, not a proven conclusion.
  Still echoes the 2016 "warm list doesn't guarantee votes" case directionally. Source:
  [happysupport.ai — Product Hunt launch roundup 2026](https://www.happysupport.ai/en/blog/product-hunt-launch-roundup-2026).
- **Founder survey (Nov 2025):** 50% saw some registration increase post-launch, 30% a
  significant increase, 16% no noticeable spike — roughly a coin-flip whether a PH launch does
  anything measurable at all.
- **AI-category saturation:** 1,111 AI launches on Product Hunt in Q2 2026 alone, +46% YoY — the
  "AI product on Product Hunt" lane specifically is now extremely crowded.
- **Channel fit now splits clearly by audience type:** X/Twitter remains the default for
  build-in-public (long-form threads, weekly metric updates) and skews developer/B2B. TikTok/
  Reels/short-form skews consumer/visual products — and the winning format flipped from polished
  sizzle reels to a quick, visible win shown in the first 1-2 seconds; narration-style "Day N of
  building my app" posts mostly underperform on TikTok specifically.
- **Smaller, trust-based communities often beat large audiences** for leads, trust, or repeat
  buyers — consistent with the 2016-era "niche channels once pain-point language is validated"
  finding.
- The founder-survey, AI-saturation, and channel-fit figures above come from multiple 2025-2026
  vendor/agency marketing blogs (self-reported, directional, not an independent benchmark study) —
  no single named source covers all of them; verify a specific figure against its own post before
  relying on it for anything beyond illustration.

**Channel-selection method — the real gap in the existing draft.** Gabriel Weinberg's **Bullseye
Framework** (from *Traction*) is the missing method:
1. **Brainstorm** all 19 traction channels (viral marketing, PR, unconventional PR, SEM, social/
   display ads, offline ads, SEO, content marketing, email marketing, engineering as marketing,
   business development, sales, affiliate programs, existing platforms, trade shows, offline
   events, speaking engagements, community building, targeting blogs) — sketch how each could
   plausibly work for *this* product, including unlikely-looking ones.
2. **Test** the top 3-5 cheaply for real signal before committing real time or money.
3. **Focus** resources on whichever one channel clearly outperforms; stop spreading effort thin
   across several.
- Prefilter by audience type before brainstorming, per the 2025-2026 update above: a developer/
  B2B audience weights the brainstorm toward X + community-building + sales/business development;
  a consumer/visual-product audience weights it toward short-form video + existing platforms
  (Product Hunt-style) — not a replacement for the three-step process, a better starting point
  for step 1.
- Source: [grahammann.net — Traction book notes](https://grahammann.net/book-notes/traction-gabriel-weinberg)
  (the 19-channel list and three-step process; the book itself is the primary source, this is a
  reliable secondary summary cross-checked against it).

**Prior-art agent skill checked:** `phuryn/pm-skills`' `gtm-strategy` skill has a 5-category
channel taxonomy (digital marketing, content/inbound, sales/outbound, community/grassroots,
product-led/viral) and a "focus on a few channels excellently" philosophy, but **no scoring
method** — exactly what Bullseye fills. Its separate `growth-loops` skill covers viral-loop
mechanics (sharing trigger, incentive, loop coefficient) once a loop-shaped channel is already
chosen — a different, complementary concern, not channel selection itself.

**Decision.** Add the Bullseye Framework (brainstorm → test 3-5 → focus, audience-type-prefiltered)
to Launch's "Build the launch plan" section as the channel-selection method it currently lacks.
**Done** (#62). Add the "launch-day traffic is a feedback spike, not a retention channel" finding
to "Choose
validation and metrics" or "Learn, decide, repeat" — respond to comments and validate pain-point
language first, then move to niche/community channels, rather than treating the launch-day number
itself as the signal. Cite real case studies (above) as illustrative tactics, not as a comparable
benchmark range — they measure different things (users, signups, referral growth, Craigslist
demand, waitlist emails) over different time windows, so don't average or range them together as
if they were one metric. Where Launch gives an expected-outcome range, use the one same-metric,
same-window source that actually supports it (e.g. the Product Hunt category benchmarks above),
not a blend across case studies. Carry the self-reported-figures caveat forward regardless.
**Done** (#63).

## Left to the builder

- ~~Implement the include-directive expansion in `scripts/mirror-skills.sh`~~ — **done**, #25/#26.
- ~~Build `skills/athene-code-health/SKILL.md` (skill 6)~~ — **done**: bugs/security/scale/
  missing-test/speed/lean, ranked, 4-part findings, per the ponytail-audit structure reviewed
  above. ~~Quantified CRAP/duplication/mutation checks on top of the qualitative audit~~ — **done**
  (#43), guidance-only: run an existing project tool where one's already configured for that
  dimension, report the gap in `Not checked:` otherwise, never bundle new tooling.
- Define the `athene:` shortcut-comment convention (parallel to ponytail's `shortcut:`/`ponytail:`)
  and a debt-ledger command/skill to grep it into a report, flagging markers with no upgrade
  trigger.
- Expand `docs/templates/claude-md-snippet.md`/`agents-md-snippet.md` to carry a condensed copy of
  the engineering-quality-bar checklist, not just the state-file routing pointer.
- Benchmark harness comparing Athene-assisted vs. unassisted builds (deferred until the `athene`
  build skill exists — nothing to measure yet).
- Broader platform packaging (beyond Claude Code/Codex/Cursor) and external distribution
  (npm/marketplace) — deferred, lower priority than shipping the build skill itself.
- Exact state-file schema/location and how Discovery/Build/Launch each update it mid-phase.
- ~~Exact format and starter contents of the curated source-index reference file~~ — **done**, see
  `docs/engineering-source-index.md`. Seeded from
  [kilimchoi/engineering-blogs](https://github.com/kilimchoi/engineering-blogs) (~218 company
  blogs, flat/alphabetical, no topic tags in the source repo), topic-mapped by hand, each entry
  carrying its real RSS/atom feed URL (pulled from that repo's `engineering_blogs.opml`, not just
  the blog homepage) so the skill fetches actual recent posts instead of guessing at a decision
  point. Covers payments, auth, ecommerce/marketplace, social/feed systems, messaging, search,
  ML-serving, distributed systems, CDN/latency, and security. Known gaps noted in that file: no
  server-management/SRE/observability source in the seed list (no Datadog/PagerDuty/Honeycomb), and
  some major distributed-systems blogs (Uber, LinkedIn) missing from the seed repo — flagged there
  for a live search or a follow-up PR, not silently left unhandled.
- ~~Per-agent MCP/connector config file locations and detection logic for Claude Code, Codex, and
  Cursor~~ — **done** as a spec, see `docs/connector-detection.md` (#21). Claude Code's paths
  confirmed against its own docs; Codex's and Cursor's are community-sourced with known gaps
  (Cursor's Windows global path conflicts across sources) flagged explicitly in that file, not
  silently asserted. Wired into `athene`'s "Stack decisions and connector setup" section (#36),
  bundled as `references/connector-detection.md` via the include-marker convention.
- ~~The exact wording/flow of the indirect project-framing question~~ — **done** for Audit, see
  `skills/athene-audit/SKILL.md`'s "Determine framing and risk tier" section (infer from scan
  first, ask once conversationally if ambiguous, never recite the four category names).
- ~~The free/paid/tier question wording and options-table format at each stack decision point~~
  — **done** as a spec, see `docs/stack-decision-process.md` (#20). Wired into `athene`'s
  "Stack decisions and connector setup" section (#36), bundled as
  `references/stack-decision-process.md` via the include-marker convention.
- ~~Risk-tier → governance-doc-set mapping table~~ — **done**, see
  `docs/governance-doc-set-mapping.md`, wired into Audit as of #19/PR #22, and into `athene`'s
  "Governance artifacts" section (#38), bundled as `references/governance-doc-set-mapping.md` via
  the include-marker convention.
- Fleshing out `agents/openai.yaml` for all five skills beyond the current placeholder.
- ~~The concrete question set/template Athene asks at each architecture decision point to
  operationalize the engineering-quality-bar checklist above~~ — **done**, see
  `docs/architecture-decision-template.md` (#37), wired into `athene`'s "Evidence-backed
  architecture and the engineering quality bar" section.
- ~~The review-gate toggle and self-review-then-wait-on-reviewer queue discipline~~ — **done** for
  `athene`, see `docs/review-gate.md`, wired into `athene`'s "Governance artifacts" section (#38),
  bundled as `references/review-gate.md` via the include-marker convention. The self-review
  subagent pass still just means "run this skill's own reviewer convention before waiting on a
  human" — no separate review-gate-specific subagent prompt was needed beyond that.
- **Known limitations surfaced during #19/PR #22's review, deliberately deferred rather than
  fixed — watch for these causing a real issue later:**
  - `scripts/set-review-gate.sh off` removes the entire branch-protection rule rather than
    restoring exactly what existed before `on` was ever run (no snapshot of that earlier state).
    A branch with unrelated protection before this script touched it loses that too on `off`.
  - The same script only manages classic GitHub branch protection, not the newer Rulesets API —
    a repo using rulesets could still require review after this script reports the gate "off".
  - Athene: Audit's commitlint step skips adding the generated CI workflow (rather than trying to
    support it) whenever an existing alternate commitlint config is in a format
    `wagoid/commitlint-github-action@v6` doesn't support (confirmed: only `.mjs`, not plain `.js`
    despite commitlint itself accepting it), or extends a third-party shareable config/plugin that
    needs the repo's own dependencies installed and exposed via `NODE_PATH` — building real
    package-manager detection and dependency installation for every possible setup was judged out
    of scope for a template workflow. In both cases Audit flags the gap in Decisions made instead
    of silently doing nothing, but commitlint-in-CI simply doesn't get set up for those repos.

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
7. Athene: Code Health (skill 6) — independent of the chain above, can land any time after the
   `shortcut:`/debt convention exists (item 8) since its findings should respect that convention.
8. `athene:` shortcut-comment convention + debt-ledger command.
9. Condensed quality-bar content in the bootstrap snippets.
10. Cursor packaging, then Codex `agents/openai.yaml` fleshing-out, last — once behavior is
    proven on one platform.
11. Benchmark harness, then broader platform reach/distribution — both after the build skill
    ships and is stable, not before.

## Gap analysis vs. prior art and current build state (researched 2026-11-06)

Re-checked three prior-art skills against Athene's *current* repo state (not the design intent) —
`git log`, every `SKILL.md` body, `docs/templates/*-snippet.md`, `scripts/debt-ledger.sh`,
`agents/openai.yaml` — rather than against the design doc's own "Left to the builder" list, which
is stale in both directions: some items it still lists as open are done (debt-ledger script, both
bootstrap snippets with condensed quality-bar content, `agents/openai.yaml` fleshed for all six
skills — not just a placeholder — per #79), and chaining (Phase 5) is done per #77/#78/#81, which
the repo's own `README.md` doesn't yet reflect either.

**What each prior-art skill actually does, confirmed (not re-describing the earlier prior-art
reviews above, just restating the load-bearing summary for this gap pass):**
- **`DietrichGebert/ponytail`** — a persona, not a process. Forces a "lazy senior developer" ladder
  before writing any code: does this need to exist at all → already in the codebase → stdlib →
  native platform feature → already-installed dependency → one line → only then new code. Marks
  every deliberate corner cut with a `ponytail:`/`shortcut:` comment naming the ceiling and upgrade
  path, greppable into a ledger via `/ponytail-debt`. Ships a benchmark harness (loc/cost/time/
  tokens/coverage, with vs. without) and a compact `AGENTS.md` carrying the real ruleset, not just a
  router. Athene already adopted the marker convention, the debt-ledger command, and condensed
  bootstrap content (see "Prior-art review: ponytail" above) — the ladder discipline *itself* is
  the one piece not adopted (see gap 2 below).
- **Caveman** (this session's own active output-style skill, `caveman:caveman` and friends) — pure
  communication-compression layer, not a build/governance skill. Drops articles, filler,
  pleasantries, and hedging from assistant prose; keeps code/commands/paths/errors verbatim; applies
  Simplified-Technical-English clarity rules (one idea per sentence, active voice, consistent
  terminology); auto-suspends for security warnings, destructive-action confirmations, and anything
  where compression itself would create ambiguity. Explicitly scoped to *chat output only* — commit
  messages, PR/issue bodies, docs, and code comments stay normal prose per its own stated boundary.
  Ships companion subagents (`cavecrew-builder`/`-investigator`/`-reviewer`) that apply the same
  compression to bounded single-file edits, read-only lookups, and diff review respectively. Athene
  has never evaluated this angle at all — it governs *what* gets built and *how rigorously*, never
  *how verbosely the agent talks about it* (see gap 4 below).
- **`unclebob/ub-mode`** — Uncle Bob's own TDD/Clean Code loop as a ~150-line skill: **First Make It
  Work** (get a failing test green with the simplest code that works, no premature design) → **Then
  Make It Right** (refactor mercilessly once green: remove duplication, fix names, apply SOLID,
  shrink functions) → **Practice** (deliberate kata-style repetition to build the reflex). Pairs with
  three companion tools for numeric gates: `crapper` (CRAP score `< 10` per function — cyclomatic
  complexity weighted by how little of the function is covered), `dryer` (structural duplication,
  Jaccard similarity `>= 0.82` flagged for merging), `mutator` (mutation testing — surviving mutants
  vs. no-coverage mutants, plus dead-code surfacing). Also: "Keep a Log" (every action plus its
  reason, reported at completion — finer-grained than a decisions-only record) and "Attack the
  Premise" (when two independent fixes hit the same gate, stop and name the shared root premise
  before trying a third). Athene adopted the numeric-gate *concept* into Code Health, guidance-only
  (see gap 5 below) and explicitly deferred the log and Attack-the-Premise pieces (see "Prior-art
  review: ub-mode" above) — the Work-then-Right *sequencing itself* was never evaluated as a gap
  until now (see gap 3 below).

**Real gaps this pass surfaces, not already tracked under "Left to the builder":**

1. **README is out of date against the repo's own commit history.** It still reads "chaining
   (Phase 5) isn't wired yet" and "`agents/openai.yaml` ... beyond the current placeholder" — both
   false as of #77/#78/#79/#81. A README that undersells finished work erodes trust in every other
   claim it makes. Fix: rewrite status section from current `git log`, not from the design doc's
   own stale phase tracker.
2. **No ponytail-style anti-overengineering ladder inside Implementation itself.** `athene`'s
   Implementation stage (lifecycle stage 4) names focused diffs and risk-proportionate tests but
   never asks "does this need to exist / is it already here / does stdlib or the platform already
   do this" *before* code gets written. `athene-code-health`'s "Lean" category catches the same
   failure mode, but only as a read-only, after-the-fact report on a repo that already has the
   bloat in it — reactive, not preventive. The cheapest fix is the cheapest point to apply it:
   before the diff exists, not after. Candidate fix: fold ponytail's ladder into Implementation as
   a check run before any new code is written, not a new skill. **Done** (#89): added as a
   "Pre-write ladder check" sub-paragraph directly inside `athene`'s Implementation lifecycle-stage
   item (same shape as "Comment discipline"), plus a new "Dependency maintenance check" covering
   the separate, previously-untracked gap that reuse of an already-chosen library never gets a
   deprecation/maintenance check (the stack-decision flow only fires at *new* stack choices), and a
   precedence note that both checks scope to implementation code only and can never cause a
   mandated governance artifact to be skipped.
3. **No explicit "make it work, then make it right" sequencing in Implementation.** The stage
   mentions tests and focused diffs but doesn't sequence them — nothing stops an agent from
   reaching for the "right" design before a single passing test exists, which is exactly the
   premature-design trap ub-mode's First-Make-It-Work step exists to block. `superpowers:test-
   driven-development` is already available in this environment and already describes this
   discipline — Athene's Implementation stage doesn't reference or require it. Candidate fix:
   Implementation names the red-green-refactor sequence explicitly and defers to that skill where
   available, rather than silently assuming the agent already does this.
4. **No stance on communication verbosity at all.** Every Athene skill governs *what* gets decided
   and *how rigorously* (ADR template, quality bar, evidence citations) but says nothing about how
   much prose the agent produces while doing it — a real axis for a skill explicitly built for
   professional engineering teams, who want decisions and diffs, not narrated deliberation. This
   was never on Athene's radar before this pass (caveman is a pure communication-style skill with
   zero process content, so earlier prior-art reviews — scoped to process/governance skills — never
   surfaced it as comparable). Not a recommendation to adopt caveman wholesale (compression is a
   user preference, not an engineering-quality property) — the gap is that Athene has no opinion
   here at all, including no guidance on PR-description or `.athene/state.md` terseness, where
   verbosity actually does cost real review time.
5. **Quantified code-quality gates are advisory-only, never enforced.** CRAP score, structural
   duplication, and mutation-testing results (from `athene-code-health`, adopting ub-mode's
   companion-tool concept) only ever appear in a one-shot report that "changes nothing," by that
   skill's own explicit scope. Nothing in `athene`'s CI/CD architecture section (pre-merge checks,
   change-aware expansion, post-merge/scheduled) ties these numbers to an actual pre-merge gate the
   way `crapper`/`dryer`/`mutator` are designed to run in CI. A repo can fail every numeric
   threshold Code Health reports and still merge cleanly. Not proposing an auto-fail gate (false
   positives on a numeric threshold are a known risk) — the gap is that there's currently no
   decision point where the user is even asked whether to wire one in.
6. **Guest-contributor and contribution-receiving-maintainer decisions are recorded, not built.**
   "External-repo personas" above records real decisions (don't impose Athene's own no-AI-
   attribution rule on a repo Athene doesn't govern; scan the target's own AI-contribution policy
   first; force disclosure for `opensource`-framed repos) — but neither `skills/athene/SKILL.md` nor
   `skills/athene-audit/SKILL.md` contains any of this logic today. An agent running this skill
   against someone else's repo right now would still apply Athene's own baseline unconditionally,
   exactly the failure mode that research warned against. Highest-priority gap in this list, since
   it's a documented behavior correctness issue, not a missing nice-to-have.
7. **No concrete security-tooling decision flow, unlike every other stack choice.** `athene`'s
   stack-decision flow (options table, self-hosted-vs-managed, pricing tier) exists for language/
   hosting/DB/CI-CD — but "security/license/secret scans" in the CI/CD architecture section is a
   bare bullet with no equivalent decision process: which secret scanner, which SCA/dependency-audit
   tool, self-hosted vs. SaaS. The engineering-quality-bar section names the OWASP checklist
   conceptually but never routes it through a concrete tool choice the way every other material
   decision in this skill does.
8. **Cursor packaging is unverified, not just unproven.** `.agents/skills/` exists and is read
   natively by Cursor per the platform-mechanics research above, but no actual run against Cursor
   has happened — "Left to the builder" already tracks this as deferred, restated here only because
   this pass specifically checked for a `.cursor/` directory and found none, confirming the gap is
   still fully open, not partially addressed by some undocumented workaround.
9. **No empirical validation anywhere, still.** Restates the ponytail-benchmark gap already named
   above — included here because it's the single largest claim-vs-evidence gap across all three
   prior-art comparisons: ponytail publishes measured numbers backing its README's claims; Athene
   has none backing its own, including the new README this task produces.

**Not re-flagged as new gaps** (already correctly tracked and unchanged by this pass): the
`athene:` marker/debt-ledger convention (done), condensed bootstrap snippets (done), benchmark
harness and broader platform reach (already deferred, same reasoning holds), "Keep a Log" and
"Attack the Premise" (already explicitly deferred with reasoning in the ub-mode review above — this
pass found no new argument to revisit that call).
