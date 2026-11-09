# Skill directory and packaging convention

## Canonical location
Source of truth for every skill: `skills/<name>/SKILL.md`. Edit only here.

## Mirroring
Each platform reads skills from its own path, not `skills/`:
- `.agents/skills/<name>/SKILL.md` — read natively by Codex and Cursor.
- `.claude/skills/<name>/SKILL.md` — read natively by Claude Code.

Mirroring is a script, not a manual step: run `scripts/mirror-skills.sh`
after adding or editing any `skills/<name>/`. It deletes and regenerates
both target folders from `skills/` (plain copy, not symlink — Windows
symlinks need elevated perms). Never hand-edit files under `.agents/skills/`
or `.claude/skills/` directly; they get overwritten on next run.

## Include markers — don't hand-copy content into a skill

A skill sometimes needs a file that's really content from elsewhere in this
repo (e.g. `docs/governance-doc-set-mapping.md`), bundled so it travels with
the skill once mirrored — a target repo won't have this repo's `docs/`
folder. Don't hand-copy that content into `skills/<name>/`; it drifts the
moment the source changes and nobody remembers to re-copy it (this happened
more than once — see `docs/design/2026-10-31-athene-design.md`'s "Reference-
copy duplication" section).

Instead, make the file under `skills/<name>/` a one-line stub:
- Markdown: `<!-- include: docs/path/to/file.md -->`
- Shell: `# include: scripts/path/to/file.sh`

`scripts/mirror-skills.sh` expands the marker into the referenced file's
full content while generating `.agents/skills/` and `.claude/skills/` — the
stub under `skills/<name>/` stays a stub (that's what you edit; you edit the
*source* file the marker points at, never the stub itself), only the
generated mirrors get the expanded content. This is the same "edit the
source, regenerate the output, never hand-edit generated files" rule the
mirroring step above already follows, extended one level deeper.

## Proof
`skills/test/` is a fixture skill kept in the repo to prove the convention
works — not a real Athene skill. Running the mirror script produces
`.agents/skills/test/SKILL.md` and `.claude/skills/test/SKILL.md`, both
identical to the source.

`skills/athene-audit/references/*.md` are real include-marker stubs proving
the expansion works: their generated copies under `.agents/skills/` and
`.claude/skills/` are byte-identical to `docs/governance-doc-set-mapping.md`
and `docs/review-gate.md`, while the stubs under `skills/` itself stay
one-line markers. The Shell form of the marker (line above) has no live
example in this repo at the moment — the two templates that used it
(`set-review-gate.sh`, `debt-ledger.sh`) were removed when those features
became agent-performed guidance instead of bundled scripts (see
`docs/review-gate-setup.md` and `docs/debt-ledger-guide.md`) — but
`scripts/mirror-skills.sh` still supports it the same way.
