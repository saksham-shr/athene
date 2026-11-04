---
name: athene-product-discovery
description: >-
  Turn an ambiguous product idea or feature request into an approved product brief - problem,
  user, outcome, scope, validation plan - then hand off to the Athene build skill. Use before
  building when the desired outcome or tradeoffs are materially unclear. Skip for a precise,
  low-risk task that can be done directly, or for an already-approved specification.
---

# Athene: Product Discovery

Use this skill for product brainstorming, feature discovery, strategy/scope conversations, and
planning a new product or capability. Skip it for a precise, low-risk task that can be completed
directly, or for a specification the user has already approved.

The goal is shared understanding, not an interrogation or a theatrical specification. Make the
user's product judgment stronger; don't substitute this skill's preferences for it.

## Check for an already-tracked repo first

Before starting discovery from zero, look for `.athene/state.md` at the repo root.

- **Not found:** this is a genuinely fresh idea with no Athene footprint yet. Continue below.
- **Found:** don't restart discovery from scratch just because this skill was invoked directly.
  Ask instead, conversationally: "Is this a new feature on top of what's already here, or a new
  idea/direction overall?"
  - **New feature on the existing project:** still goes through the discovery flow below, but
    framed against what's already built rather than from a blank slate — read the state file's
    `Decisions made` first so earlier choices aren't re-litigated. This path does update
    `.athene/state.md` as usual (see "State handling" below), since the feature belongs to the
    same tracked initiative.
  - **New idea/direction overall:** a separate initiative. Run discovery for it in conversation
    only — don't write to `.athene/state.md` while exploring it. That file is this repo's single,
    shared record of whichever initiative currently owns it; writing to it mid-discovery for a
    second, unrelated initiative would overwrite or fork the existing project's own ownership
    record, and a later Resume or `athene` run would have no way to tell which initiative it's
    actually continuing. Only touch `.athene/state.md` once the new idea is approved and the user
    has explicitly decided it should take over this repo going forward — at that point it's a
    deliberate handoff, not a side effect of running discovery.

## Discover the intent

Start from the context already supplied. If a material gap remains, ask one natural,
high-leverage question at a time. Prefer concrete prompts such as:

- "Walk me through the last time this problem happened."
- "Who is struggling, and what do they do instead today?"
- "If this could only do one thing exceptionally well, what is it?"
- "What outcome would make this feel like a failure despite technically working?"

Learn only what changes the recommendation: audience, problem/job, current workaround, desired
outcome, constraints, evidence, risks, timing, and who decides. State useful assumptions so the
user can correct them. Treat guesses as hypotheses, not facts.

**Only on the existing-project branch above:** if `.athene/state.md`'s Decisions made already
holds a framing decision, reuse it and skip this question — don't re-litigate it. On the
new-idea/new-direction branch, or when no `.athene/state.md` exists at all, the existing project's
framing (if any) doesn't apply to this separate initiative — determine framing fresh in
conversation, and keep the result out of `.athene/state.md` until the user explicitly approves
takeover (see above), recording it as part of that handoff rather than mid-discovery. Otherwise
ask the project-framing question early — `opensource`, `startup`, `personal`, or `research` —
conversationally, never by reciting those four category names (same indirect approach as
`skills/athene-audit/SKILL.md`'s "Determine framing and risk tier"): *"One thing before I go
further — who's this really for: just you right now, outside contributors or users you don't
control, a team or customers depending on it, or is it feeding research or coursework?"* Map the
answer to a category yourself; don't make the user pick a label. Record the result and why in
`.athene/state.md`'s Decisions made — `athene`'s own framing/risk-tier determination (see its
"Governance artifacts" section) reads this back rather than re-asking it from scratch.

When research, repository inspection, customer material, or market comparison would materially
reduce uncertainty, propose the narrow research question and source scope before doing it.
Distinguish evidence, user-stated facts, assumptions, and open questions in the result.

## Generate and choose options

Think broadly privately, discard weak ideas, and present two or three genuinely different viable
approaches only when a choice matters. For each, state:

- The target user and core value.
- What it deliberately excludes.
- Main benefit, cost, risk, and dependency.
- The smallest test or experiment that could disprove it.

Recommend an approach when the available evidence supports one. Explain the tradeoff plainly and
leave the final product choice with the user. Don't manufacture alternatives when there is one
clearly proportionate solution.

Offer a simple sketch, user flow, comparison table, or throwaway prototype when seeing the idea
would resolve ambiguity faster than prose. A spike is explicitly disposable: it has a narrow
question, limited scope, no implication it will be productionized, and no implementation work
beyond what the user approved.

## Scope deliberately

Define the smallest valuable first release as user capability and outcome — not a list of screens
or technologies. Keep three lists:

- **Now:** the essential user journey and acceptance criteria.
- **Later:** valuable but nonessential extensions.
- **Never / not now:** tempting work that would dilute the first outcome or violate a constraint.

Name critical assumptions and choose a validation method for each: interview, prototype,
usability test, manual workflow, technical spike, metric, or staged release. Avoid false
precision in estimates; use ranges and explain the uncertainty driver.

## Produce the handoff

For a material product initiative, create a concise product brief containing:

```text
Problem and target user
Desired outcome and measurable success signal
Current alternatives and why they fall short
Product proposition and primary user journey
Scope: now / later / not now
Constraints, risks, assumptions and validation plan
Key decisions made and remaining decisions
Acceptance criteria and launch/learning plan
```

For software, add only the architectural choices the user actually made or that are necessary to
estimate/plan responsibly: major integrations, data/privacy boundaries, compatibility, and
operational requirements. Leave implementation detail to `athene` (the build skill).

Present the brief back in plain language. Before starting production implementation, obtain
explicit approval for the product shape, scope, material tradeoffs, and any irreversible/external
commitment.

## Product-quality checks

Before calling discovery complete, verify that:

- The problem is expressed independently of the proposed solution.
- A specific user can recognize the promised outcome.
- The first release is small enough to learn from but complete enough to be useful.
- Success and failure signals can be observed after launch.
- Risks around security, privacy, accessibility, cost, reliability, abuse, and support have
  appropriate owners.
- Open questions are visible; the plan doesn't pretend they're resolved.

Keep the conversation adaptive. A clear product request may need only a short playback and
approval; an uncertain or consequential bet deserves deeper discovery.

## State handling

Create or update `.athene/state.md` as a committed plain-Markdown file, self-contained spec below
(this file doesn't travel with the skill once mirrored elsewhere, so don't cross-reference it by
path). Write it at the end of this skill's turn/session, not mid-task:

- Four headings, in this exact order, each required — `none`/`n/a` rather than omitting one:
  `## Active skill`, `## Current phase`, `## Decisions made`, `## Open questions`.
- **Active skill:** `athene-product-discovery` — this skill's own frontmatter `name`, while this
  skill owns the repo. Set to `athene`'s frontmatter name once handed off (see below).
- **Current phase:** one of this skill's own stages above (`discover-intent`, `generate-options`,
  `scope`, `produce-handoff`, `quality-checks`), while `Active skill` is
  `athene-product-discovery`.
- **Decisions made:** bullet list, append-only. What was chosen and why, in the order decided.
- **Open questions:** bullet list. Anything genuinely unresolved. `none` if nothing's outstanding.

## Handoff

Once the brief is approved, confirm the `athene` skill file is packaged where this skill is
installed. If it isn't, say so explicitly and stop there rather than claiming a handoff that
can't happen, instead of guessing at `athene`'s behavior.

If it is packaged, update `.athene/state.md`: set `Active skill` to `athene` and `Current phase`
to `handoff` — the shared reserved value both skills agree means "just arrived, haven't started
your own stages yet", not one of this skill's own phase names, which would belong to a lifecycle
`athene` doesn't run. Then read and follow the `athene` skill file directly — a plain
read-and-follow instruction, not a platform-specific invoke call.
