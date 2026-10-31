#!/usr/bin/env bash
# Mirrors every skills/<name>/ folder (canonical source) into the two paths
# each platform reads natively: .agents/skills/ (Codex + Cursor) and
# .claude/skills/ (Claude Code). Plain copy, not symlink — Windows symlinks
# need elevated perms, copies don't.
set -euo pipefail

cd "$(dirname "$0")/.."

rm -rf .agents/skills .claude/skills
mkdir -p .agents/skills .claude/skills

for dir in skills/*/; do
  name="$(basename "$dir")"
  cp -r "$dir" ".agents/skills/$name"
  cp -r "$dir" ".claude/skills/$name"
done

echo "Mirrored $(ls -d skills/*/ | wc -l) skill(s) into .agents/skills/ and .claude/skills/"
