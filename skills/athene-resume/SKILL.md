---
name: athene-resume
description: Pick up an Athene-tracked repo exactly where it left off: read .athene/state.md for current phase, decisions made, and open questions, then continue from there. Skip when .athene/state.md doesn't exist - hand off to Athene: Audit instead.
---

# Athene: Resume

Use this skill at the start of a session on a repo that may already have Athene state in it —
before assuming a fresh start, before re-asking questions already answered, before re-deciding
anything already decided.

## Check for state

Look for `.athene/state.md` at the repo root. Schema: `docs/state-schema.md` in Athene's own repo.

- **Not found:** there is nothing to resume. Read and follow the Athene: Audit skill file
  directly — a plain read-and-follow instruction, not a platform-specific invoke call. Stop here;
  the rest of this skill doesn't apply.
- **Found:** continue below.

## Report and continue

Read all four sections and report them to the user before doing anything else:

- **Active skill** — which Athene skill owns the repo right now.
- **Current phase** — where that skill is in its own lifecycle.
- **Decisions made** — the full list, not a summary. These are settled; don't re-open them or
  re-ask questions they already answer.
- **Open questions** — what's still unresolved. These are exactly what blocks continuing.

Then read and follow whichever skill file `Active skill` names, picking up at `Current phase`.
Don't restart that skill's flow from its own beginning.

## Update rule

Resume only reads `.athene/state.md`. It never writes to it — updating state belongs to whichever
skill is active once control passes to it.
