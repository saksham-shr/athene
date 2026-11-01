# Stack-decision process

The format skill 2 (Athene build) uses at every material build choice (language, hosting, DB,
domain, CI/CD tool, at minimum) — per the design doc's "Stack decisions" and "Evidence-backed
architecture" sections. **Not yet wired into any skill:** `athene`, the skill this feeds, doesn't
exist in this repo yet (external draft only, not built here). This is the standalone spec that
skill will consume once built — same pattern as `docs/governance-doc-set-mapping.md` before
#19 wired it into Audit.

## The options table

For each material choice, present candidates side by side, not a single pre-picked answer:

| Candidate | Pros | Cons |
|---|---|---|
| ... | ... | ... |

2-3 real candidates minimum. Pull evidence from `docs/engineering-source-index.md` where a topic
entry exists — follow that file's own "How this gets used" steps (identify topic, pull the real
feed, read the actual post, cite it) rather than writing generic pros/cons from memory. If no
entry covers the topic, search live per that file's existing fallback rule, don't skip evidence.

## The tier question

Asked **after** the table, never before it, and never as a raw budget figure:

*"Free, paid, or paid-and-which-tier?"* — adapted to the specific choice, e.g. for a database:
*"Free tier/self-hosted, a paid managed plan, or a specific paid tier you already know you need?"*

Never ask "what's your budget." The options table already showed the cost-relevant tradeoffs;
this question just picks where on that table the user wants to land.

## Recording the decision

Per `docs/state-schema.md`'s Decisions made field: append-only, what was chosen and why, one
line. Cite the specific evidence used (e.g. "chose Postgres over SQLite — need concurrent writes
from day one, per Stripe's blog post on connection pooling at scale"), not "best practices say."

## Worked example — "pick a database"

| Candidate | Pros | Cons |
|---|---|---|
| PostgreSQL | Real concurrent writes, mature tooling, works for almost any workload | Needs a managed instance or self-hosting; more setup than SQLite |
| SQLite | Zero setup, file-based, great for low-traffic/single-writer apps | No real concurrent writes; wrong choice once multiple processes write at once |
| MongoDB | Flexible schema, easy horizontal scaling for document-shaped data | Wrong tool if the data is actually relational; weaker consistency guarantees by default |

Tier question: *"Free tier/self-hosted Postgres, or a managed paid plan (and if so, which tier)?"*

Recorded decision (example): *"Stack: Postgres over SQLite — need concurrent writes from day
one; self-hosted for now per user's free-tier answer."*
