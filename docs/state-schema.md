# `.athene/state.md` schema

Shared state file every Athene skill reads and writes. Lets Resume and Audit
pick up a repo cold.

- **Location:** `.athene/state.md`
- **Format:** plain markdown, committed (not gitignored) — must survive across
  machines, agents, and sessions.

## Fields

Four fixed sections, in this order. Each is required; use "none" or "n/a" if
empty, don't omit the heading.

### Active skill
Which Athene skill owns the repo right now (Product Discovery, Athene build,
Launch, Audit, Resume).

### Current phase
Where that skill is in its own lifecycle (e.g. "intake", "triage", "design",
"implementation", "post-launch review"). One line.

### Decisions made
Bullet list. Each decision: what was chosen, one-line why. Append-only —
never delete a past decision, only add new ones.

### Open questions
Bullet list of unresolved questions blocking progress. Remove a question once
answered (fold the answer into Decisions made).

## Update rule

Whichever skill is active updates this file at the end of its turn/session,
not mid-task. Resume only reads it, never writes it. Audit is the one
exception: it writes this file once, to bootstrap it where none exists yet —
after that initial write, Audit's own involvement ends and the skill named in
`Active skill` takes over updates.
