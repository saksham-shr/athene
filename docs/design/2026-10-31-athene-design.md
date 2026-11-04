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

## Skills (6) and the flow

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
what's found — ban/maintainers-only (don't open the PR, tell the user why), disclosure-required
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

## Left to the builder

- ~~Implement the include-directive expansion in `scripts/mirror-skills.sh`~~ — **done**, #25/#26.
- ~~Build `skills/athene-code-health/SKILL.md` (skill 6)~~ — **done**: bugs/security/scale/
  missing-test/speed/lean, ranked, 4-part findings, per the ponytail-audit structure reviewed
  above. Still open: quantified CRAP/duplication/mutation thresholds on top of the qualitative
  audit — tracked as #43, see the `ub-mode` prior-art review above.
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
