# Contributing

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`.

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`, `build`.

- `feat` — a new capability for a user.
- `fix` — a bug fix.
- `chore` — maintenance work with no user-facing effect (deps, config, tooling).
- `docs` — documentation only.
- `refactor` — code change that doesn't fix a bug or add a feature.
- `test` — adding or correcting tests.
- `perf` — a change that improves performance.
- `ci` — CI configuration and scripts.
- `build` — build system or external dependency changes.

Scope is optional but preferred: `feat(auth): add password reset flow`.

## Shortcut markers

Mark a deliberate simplification that cuts a real corner with a known ceiling
and upgrade path:

```
# athene: <ceiling>, <upgrade path>
```

Example: `# athene: global lock, per-account locks if throughput matters`.

Use it for a real shortcut with a known limit - a naive algorithm, a global
lock, a hardcoded cap - not every TODO. Ask your AI agent for a debt-ledger
report any time; it scans the repo live for this marker and flags any
instance with no named upgrade path (no comma after the ceiling) as rot
risk. No script to run yourself - it's a live scan, not a maintained tool.

`athene:` stays distinguishable from `ponytail:`'s own marker in a repo that
uses both skills.

## No AI attribution

Commit messages and PR descriptions never carry an AI attribution or co-author trailer,
regardless of which agent wrote them. This applies equally to every contributor, human or AI.

## Issue/PR checklist items stay one line

GitHub renders every top-level `- [ ]` item in an issue/PR body as a tracked-task row: a drag
handle and an overflow menu on the right, in space reserved regardless of how much text the item
holds. A checklist item long enough to wrap to two or more lines leaves that reserved space empty
next to a short first line and a second line underneath it — reads as a layout bug, isn't one.

Keep each `- [ ]` item to one line, one concrete action. A task that needs more explanation than
that fits on one line belongs in `## Context` or `## Proposal` above the checklist, with the
checklist item itself staying a short pointer back to it — not the explanation stuffed into the
checklist line itself.

## Write issue/PR paragraphs as one line, let the browser wrap them

GitHub renders a single newline inside an issue or PR body as an actual line break — unlike a
`.md` file committed to the repo (a README, this file), where a soft newline inside a paragraph
just collapses into a space when rendered. Hand-wrapping a paragraph at ~70-80 characters — the
habit that makes a `.md` file or a terminal heredoc readable in a source editor — produces a wall
of short, forced lines on GitHub's issue/PR view instead of one flowing paragraph: each source
line becomes its own visually separate line, with empty space on the right and the next sentence
appearing to start on a new line even when it's a direct continuation.

Write each paragraph in an issue or PR body as a single unbroken line in the source, however long
that line gets — don't wrap it by hand. A blank line still separates paragraphs normally; only the
within-paragraph wrapping habit is different here from every other Markdown file in this repo.
