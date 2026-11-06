# Athene

Athene is a connected set of agent skills that makes an AI coding agent behave like a disciplined
engineering team by default — not a code generator that happens to also write tests sometimes.

Point an AI agent at a real engineering org and it quietly skips the parts nobody told it to do:
no issue/PR discipline, no review gate, no CI/CD design, no evidence-backed architecture decisions,
no governance, no sense of when *not* to ship a feature. Athene is the missing layer: discover the
right thing to build, build it with real repo hygiene and an actual engineering quality bar, launch
the smallest version that teaches you something, and pick the work back up — or retrofit the same
discipline onto a repo that already exists — without re-litigating decisions already made.

This is built for engineering teams and the people who ship code professionally, not a tutorial
layer for people who've never touched a terminal. The governance it generates (CODEOWNERS, branch
protection, commitlint, SECURITY.md) and the engineering quality bar it enforces (threat modeling,
latency budgets, fault tolerance, checklist-driven review) assume a real production repo with real
consequences for getting it wrong.

**The core differentiator: research before code, every time.** Before a single line gets written
for a feature or function, `athene` reads real engineering sources — company eng blogs, the actual
stack already in the target repo, what the user is actually trying to build — and matches the
decision against that evidence, not the model's memory. A payments feature pulls from Stripe's
own engineering writing; a search feature pulls from a search-engineering source; an unindexed
topic triggers a live search rather than a guess. Nothing gets built off vibes. See "Evidence-
backed architecture" under the `athene` skill below.

## Status

All six skills exist with a built core, and the full chain runs end to end: Discovery → Athene
(build) → Launch hands off automatically, without the user naming the next skill. Governance
generation, the stack-decision flow, evidence-backed architecture, and the review gate are done.
Packaging covers Claude Code and Codex/Cursor's shared skills path.

## The six skills

Live, in [`skills/`](skills/). Each skill's file ends with an explicit "read and follow the next
skill file" instruction, so the chain below runs without the user naming the next step.

```
Product Discovery ──► Athene (build) ──► Launch ──► (pivot) back to Product Discovery
        ▲                    ▲                             │ (otherwise: cycle ends)
        │                    │
   Resume ──reads .athene/state.md──┘
        │
   Audit ──(no state file found)
```

- **`athene-product-discovery`** — turns an ambiguous idea into an approved product brief. Maps
  3–7 customer opportunities (Opportunity Solution Tree), scores them by
  `Importance × (1 − Satisfaction)` where real evidence supports it, generates 2–3 genuinely
  different solution options for the top-scored opportunity, scopes a now/later/never release, and
  names discovery anti-patterns to watch for (solution-first discovery, sample-of-one, proxy
  research, leading the witness, HiPPO-driven decisions). Hands off to `athene`.

- **`athene`** — the core build skill: lifecycle, ownership, CI/CD, stack decisions, architecture,
  governance, and the review gate. Eight lifecycle stages (Intake → Triage → Design →
  Implementation → PR intake → Review → CI/merge → Release). At every material stack choice
  (language, hosting, DB, CI/CD tool) it presents a real options table, asks self-hosted-vs-managed
  then pricing tier — never a raw budget number — and auto-detects or sets up the matching
  MCP/connector. Every nontrivial architecture decision gets an ADR-style
  problem → constraints → options → quality-bar check → decision → consequences note, backed by a
  curated index of real engineering blogs (payments, auth, ecommerce, distributed systems,
  security, and more) with a live-search-plus-issue-draft fallback for anything uncovered. Writes
  real governance artifacts into the target repo — CONTRIBUTING.md, PR/issue templates, a
  risk-tier-scaled CODEOWNERS/SECURITY.md/commitlint/release-policy set — and runs a self-review
  subagent pass (including a comment proof-test: every surviving comment needs a genuinely external
  justification, or it gets converted into real enforcement instead) before any PR waits on a human
  reviewer. A branch-protection review gate exists as a real toggle, default off. Hands off to
  `athene-launch`.

- **`athene-launch`** — defines the smallest learning release, pairs each risky assumption with an
  observable signal and a decision rule (never a vanity metric), picks channels with the Bullseye
  Framework (brainstorm 19 traction channels → test the top 3–5 cheaply → focus on whichever one
  wins), and runs the post-launch review: continue, reposition, fix the core workflow, test a new
  hypothesis, expand the cohort, or stop. Only "test a new hypothesis" loops back to Discovery.

- **`athene-audit`** — the onboarding path for a repo that was never set up with Athene. Scans
  structure, policies, CI, and ownership before writing anything; determines project framing
  (opensource/startup/personal/research) and risk tier without ever reciting those labels as a
  form; writes the same governance artifact set `athene` would, risk-scaled; offers the review-gate
  toggle without flipping it; bootstraps `.athene/state.md` so the project can be tracked going
  forward.

- **`athene-resume`** — session-start continuity. Reads `.athene/state.md`, reports all four
  sections verbatim (active skill, current phase, decisions made, open questions), then hands
  control to whichever skill is actually active, picking up at its current phase rather than
  restarting it. Read-only — never writes state itself.

- **`athene-code-health`** — a one-shot, read-only whole-repo quality audit, distinct from Audit's
  process-only scope. Maps the repo and its expected load, then finds in order: bugs, security/
  data-loss risk, scale limits, missing tests on risky logic, real slowdowns, and lean findings
  (dead code, duplication, over-abstraction, comment slop). Runs CRAP-score, structural-duplication,
  and mutation-testing checks where a matching tool is already configured in the repo — never adds
  new tooling to compute them. Every finding needs a concrete failure case; output is ranked
  Must-fix / Should-fix / Nice-to-have, capped at 20, ending in a one-line verdict.

## What makes this different from "just ask the agent to be careful"

- **Research runs before code, not after.** For any nontrivial feature or function, `athene`
  reads what's actually in the target repo (stack already chosen, conventions already set) and
  consults real engineering sources matched to the topic — not a generic "best practices" recall
  from the model's memory, and not research done once then forgotten: it happens per decision,
  scoped to what the user is actually asking to build. No matching source → live search, then a
  drafted issue proposing the new source rather than silently guessing and moving on.
- **State survives the session.** `.athene/state.md` is a committed, plain-Markdown file with four
  required sections (active skill, current phase, decisions made, open questions) that every skill
  reads before acting and `athene-resume` reports verbatim at the start of every session. Decisions
  are append-only — nothing gets silently re-litigated.
- **Governance is generated, not just suggested.** CONTRIBUTING.md, PR/issue templates, CODEOWNERS,
  SECURITY.md, commitlint config and CI, and a release/tag policy doc are real files written into
  the target repo, scaled by project framing and risk tier — not advice left in a chat transcript.
- **A shortcut has to admit it's a shortcut.** Every deliberate simplification gets an `athene:`
  comment naming its ceiling and upgrade trigger; `scripts/debt-ledger.sh` greps the whole repo for
  markers with no real upgrade path and flags them as rot risk.
- **Architecture decisions cite real evidence**, not the agent's memory — a curated index of
  engineering-blog sources per topic, with a live-search-and-propose-a-new-source fallback instead
  of silently guessing.
- **A PR gets a self-review pass before a human ever sees it**, including a proof-test on every
  comment left in the diff: a comment survives only with a genuinely external justification, or it
  gets replaced with real enforcement (a type, an assertion, a test, a lint rule) before the comment
  is deleted.
- **Launch discipline resists feature creep on purpose.** Every scope addition during Launch gets
  challenged against "does this increase our ability to learn the launch question, or just make the
  product feel more complete?"

## Prior art this project studied, and what it did and didn't adopt

Three existing agent-skill projects were reviewed in depth before and during the build — not
copied wholesale, but mined for real gaps:

- **[`DietrichGebert/ponytail`](https://github.com/DietrichGebert/ponytail)** — a "lazy senior
  developer" persona: a ladder (does this need to exist → already in the codebase → stdlib → native
  platform feature → already-installed dependency → one line → only then new code) run before any
  code gets written, deliberate shortcuts marked with a `ponytail:`/`shortcut:` comment and swept
  into a debt ledger, a compact `AGENTS.md` carrying the real ruleset instead of just a router, and
  a published benchmark harness comparing assisted vs. unassisted runs. Athene adopted the marker
  convention, the debt-ledger command, and condensed bootstrap content.
- **[`unclebob/ub-mode`](https://github.com/unclebob/ub-mode)** — Uncle Bob's TDD/Clean Code loop
  as a skill: First Make It Work (simplest code that passes a failing test, no premature design) →
  Then Make It Right (refactor once green — remove duplication, fix names, apply SOLID) → Practice.
  Pairs with companion tools enforcing numeric gates (CRAP score `< 10` per function, structural
  duplication `>= 0.82` Jaccard flagged for merging, mutation testing for undertested/dead code).
  Athene adopted the numeric-gate concept into Code Health, guidance-only.
- **Caveman** — a pure communication-compression layer, not a build or governance skill: drops
  filler from assistant prose, keeps code/commands/errors verbatim, auto-suspends for safety-
  critical or destructive-action warnings, and explicitly never touches commit messages, PR bodies,
  docs, or code comments.

## Contributing

Conventional Commits types, PR template, issue templates: see
[`skills/athene-audit/templates/`](skills/athene-audit/templates/) — the same baseline Athene
writes into target repos.
