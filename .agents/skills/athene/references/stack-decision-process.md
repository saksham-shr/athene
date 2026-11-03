# Stack-decision process

The format skill 2 (Athene build) uses at every material build choice (language, hosting, DB,
domain, CI/CD tool, at minimum) — per the design doc's "Stack decisions" and "Evidence-backed
architecture" sections. **Wired into `athene`'s "Stack decisions and connector setup" section**
(#36) — this file is bundled there as `references/stack-decision-process.md` via the
include-marker convention, same pattern `docs/governance-doc-set-mapping.md` followed when #19
wired it into Audit.

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

Asked **after** the table, never before it, and never as a raw budget figure. Two separate
choices, not one combined question — deployment model and pricing tier are different decisions
with different operational implications, don't conflate them:

1. **Deployment:** self-hosted, or a managed service?
2. **Pricing tier** (only if managed): *"Free tier, paid, or a specific paid tier you already
   know you need?"*

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
| SQLite | Zero setup, file-based, great for low-traffic/single-writer apps | Multiple processes can connect, but writes serialize — contention under concurrent writers; wrong choice once write concurrency is actually high |
| MongoDB | Flexible schema, easy horizontal scaling for document-shaped data | Wrong tool if the data is actually relational; weaker consistency guarantees by default |

Deployment question: *"Self-hosted Postgres, or a managed service?"* → user picks self-hosted.
(Pricing-tier question skipped — only asked when the user picks managed.)

Recorded decisions (example) — one entry per decision, per `docs/state-schema.md`'s append-only
format:

- *"Stack: Postgres over SQLite — need concurrent writes from day one, SQLite serializes
  writers under contention per [SQLite's own FAQ](https://www.sqlite.org/faq.html)."*
- *"Deployment: self-hosted — per user's answer."*
