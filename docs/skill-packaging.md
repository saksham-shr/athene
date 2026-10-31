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

## Proof
`skills/test/` is a fixture skill kept in the repo to prove the convention
works — not a real Athene skill. Running the mirror script produces
`.agents/skills/test/SKILL.md` and `.claude/skills/test/SKILL.md`, both
identical to the source.
