# Skill description style guide

The `description` frontmatter field is the only part of a skill always in
context, on every platform (Claude Code, Codex, Cursor) — it's the sole basis
for auto-invocation. Body content never loads until the skill already fired,
so "when to skip" belongs in the field itself, not buried in the body intro.

## Format

One sentence (two max), in this order:
1. **Front-loaded trigger words** — lead with the verbs/nouns a user's real
   phrasing would contain, not a category label.
2. **When to use** — the concrete situation that should fire this skill.
3. **When to skip** — the adjacent situation that should NOT fire it. Required.
   Without this, a skill with a broad trigger match fires on requests another
   skill should own.

## Length ceiling

**300 characters.** Codex caps the whole discovery list (every installed
skill's name+description) at ~8000 chars by default — one bloated
description crowds out others, and long descriptions get truncated first.

## Applying the guide to the 3 existing draft skills

Source: `athene/SKILL.md`, `athene-launch/SKILL.md`,
`athene-product-discovery/SKILL.md` (drafts, not yet in this repo).

| Skill | Length | Trigger words | When to use | When to skip (in description) |
|---|---|---|---|---|
| `athene` | 197 chars | pass | pass | **fail** — skip clause is in the body intro, not the description |
| `athene-launch` | 195 chars | pass | pass | **fail** — same, skip clause lives in body only |
| `athene-product-discovery` | 240 chars | pass | pass | **fail** — same |

All three pass length and lead with usable trigger verbs. All three fail the
same way: each has a good skip condition, but it's written into the body
(loaded only after the skill already triggered), not the description. Flagged
for rewrite — move the existing skip sentence from each body intro into the
description field, e.g.:

- `athene`: append `. Skip for a one-off CI fix or a single generic coding task.`
- `athene-launch`: append `. Skip if nothing is near ready to ship.`
- `athene-product-discovery`: append `. Skip for an already-approved spec or a low-risk task doable directly.`
