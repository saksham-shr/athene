# Architecture decision template

Operationalizes the engineering-quality-bar checklist from
`docs/design/2026-10-31-athene-design.md`'s "Engineering quality bar: veteran-engineer posture"
section into a real template, for skill 2 (`athene-build`) to use at each nontrivial design decision
during the Design lifecycle stage — stack-decision-process.md's options table covers *stack
choices* (database, hosting, etc.); this covers *architecture* decisions (how a feature's data
flows, where state lives, how a system handles failure).

## First: is this even reversible?

If the choice is changeable in under a week of work, skip the template below — decide fast,
record the decision and why in `.athene/state.md` like any other decision, and move on. The full
template is for decisions a future engineer would reasonably ask "why was this done this way,"
not every small call.

## The template

```
## Architecture decision: <name>

**Problem:** <one or two sentences — what this actually needs to solve>
**Constraints:** <real constraints — existing stack, team size, a deadline, a legacy system it
must talk to>
**Requirements, as numbers, not vibes:** <e.g. "renders in under 200ms," not "should be fast">

**Options considered:**

| Option | Tradeoffs |
|---|---|
| ... | ... |

**Quality-bar check** — apply what's relevant to *this* decision, skip what isn't; this is a
checklist to consult, not a form every box must be filled on:
- **Non-functional:** which of scale, latency, fault tolerance, durability, compliance actually
  matters here — with a number, not a goal.
- **Security:** threat-modeled before building, not after? Inputs validated? Vetted
  libraries over hand-rolled auth/crypto?
- **Performance:** a latency budget set before building? Any optimization justified by a
  measured number, not guesswork?
- **Operations:** SLOs/observability wired in from day one, not bolted on after an incident?
- **Edge cases:** empty/null inputs, boundary conditions, concurrent access considered?

**Decision:** <chosen option — cite the real evidence behind it, from
`references/engineering-source-index.md` or a live search per
`references/source-index-live-search.md`, not a vague "best practices say">
**Consequences:** <what this commits to, what it gives up>
**Revisit when:** <the concrete trigger — "if traffic exceeds X," not "later">
```

## Recording it

The chosen decision becomes one entry in `.athene/state.md`'s Decisions made — the
template is how the decision gets *made*, not a separate file that sits alongside state.md.
Record the decision and its one-line why there, same as any other decision; keep the full
template's reasoning in the conversation/PR description if it's worth preserving at length, not
duplicated into the state file.
