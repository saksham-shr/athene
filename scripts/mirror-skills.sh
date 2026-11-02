#!/usr/bin/env bash
# Mirrors every skills/<name>/ folder (canonical source) into the two paths
# each platform reads natively: .agents/skills/ (Codex + Cursor) and
# .claude/skills/ (Claude Code). Plain copy, not symlink — Windows symlinks
# need elevated perms, copies don't.
#
# Expands include markers while copying, so skills/ can hold a thin stub
# pointing at docs/ or scripts/ instead of a hand-copied duplicate that goes
# stale. Markdown: a file whose first line is exactly
# "<!-- include: path/to/file -->" has its whole content replaced by that
# file's content. Shell: a file whose first line is exactly
# "# include: path/to/file" gets the same treatment. skills/ itself keeps the
# stub (edit it there); only the generated .agents/skills/ and .claude/skills/
# copies get the expanded content.
set -euo pipefail

cd "$(dirname "$0")/.."
root="$PWD"

expand_includes() {
  local dest_dir="$1"
  local file marker target
  while IFS= read -r -d '' file; do
    marker="$(head -n1 "$file" 2>/dev/null | tr -d '\r' || true)"
    target=""
    if [[ "$marker" =~ ^\<!--\ include:\ (.+)\ --\>$ ]]; then
      target="${BASH_REMATCH[1]}"
    elif [[ "$marker" =~ ^#\ include:\ (.+)$ ]]; then
      target="${BASH_REMATCH[1]}"
    fi
    if [ -n "$target" ]; then
      if [ ! -f "$root/$target" ]; then
        echo "mirror-skills.sh: include target not found: $target (referenced from $file)" >&2
        exit 1
      fi
      cp "$root/$target" "$file"
    fi
  done < <(find "$dest_dir" -type f -print0)
}

rm -rf .agents/skills .claude/skills
mkdir -p .agents/skills .claude/skills

for dir in skills/*/; do
  name="$(basename "$dir")"
  cp -r "$dir" ".agents/skills/$name"
  cp -r "$dir" ".claude/skills/$name"
  expand_includes ".agents/skills/$name"
  expand_includes ".claude/skills/$name"
done

echo "Mirrored $(ls -d skills/*/ | wc -l) skill(s) into .agents/skills/ and .claude/skills/"
