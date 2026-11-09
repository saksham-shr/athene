# Debt ledger — agent-performed scan, no bundled script

Earlier versions shipped `scripts/debt-ledger.sh` into every target repo (via
`templates/debt-ledger.sh`) to scan for `athene:` shortcut markers (see `CONTRIBUTING.md`'s
"Shortcut markers" section). That script is gone from the published package — nothing is copied
into the target repo for this any more. Instead, run this scan yourself, live, with your own
Grep/Bash tool, whenever the user asks for a debt-ledger report. Nothing to install, nothing that
can go stale in the target repo.

## What to search for

A real `athene:` marker is a comment prefix (`#`, `//`, or `/*`, optional single space)
immediately followed by `athene:` — a bare substring match on the word "athene" catches
unrelated prose and false-positives constantly. Search tracked **and untracked** files (a marker
in a file nobody's committed yet still counts), excluding Markdown (a real marker lives in code,
never in a doc describing the convention).

Equivalent to: `git grep --untracked --no-recurse-submodules -n -I -E '(#|//|/\*) ?athene:' --
':!*.md'` run from the repo root (not the caller's cwd — `git grep` only searches the current
directory and below, so running this from a subdirectory would silently miss markers elsewhere).
Using your own search tool instead of shelling out is fine and preferred; this is the pattern to
match, not a command you're required to run verbatim.

## Classifying each match

For each match, take the text after `athene:` on that line. If it's inside a `/* ... */` block
comment, strip the closing `*/` and anything after it before judging the content — otherwise
trailing code on the same line reads as part of the marker.

- **Has a named upgrade path:** the text contains a comma, and there's real, non-whitespace
  content after it (the ceiling, then `, <upgrade path>`). This is a deliberate, disclosed
  shortcut — not a finding, just information.
- **No named upgrade path:** no comma, or a comma with nothing meaningful after it. Flag as
  **rot risk** — a shortcut was taken but nobody named when or how to revisit it.

## Reporting

Group by file, then by line, in the order found. For each marker, show the line number and the
full marker text; append `[ROT RISK: no upgrade trigger named]` to any flagged as rot risk. End
with a one-line summary: total markers found, and how many are flagged as rot risk. No markers
found: say so plainly, don't fabricate a finding to seem thorough.

This is a report only — reading the repo, never writing to it. Fixing a flagged shortcut (adding
the missing upgrade path, or actually doing the upgrade) is a separate, explicit task the user
asks for next, not something this scan does on its own.
