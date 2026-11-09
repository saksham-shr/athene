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

## Packaging check
`scripts/check-skill-packaging.sh` asserts three things in one run: `skills/`,
`.agents/skills/`, and `.claude/skills/` each contain exactly the seven
production skills (no fixture or stray directory leaked in, nothing missing),
and the mirrors are current (it re-runs `scripts/mirror-skills.sh` and fails
if that produces an uncommitted diff). A fixture skill once lived at
`skills/test/` only to prove the mirroring convention worked; this check
proves the same thing on every real skill instead, so the fixture was
removed rather than shipped alongside the production set.

`skills/athene-audit/references/*.md` and `templates/set-review-gate.sh` are
real include-marker stubs proving the expansion works: their generated
copies under `.agents/skills/` and `.claude/skills/` are byte-identical to
`docs/governance-doc-set-mapping.md`, `docs/review-gate.md`, and
`scripts/set-review-gate.sh` respectively, while the stubs under `skills/`
itself stay one-line markers.
