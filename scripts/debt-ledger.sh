#!/usr/bin/env bash
# Greps the repo for real `athene:` shortcut markers (see CONTRIBUTING.md's
# "Shortcut markers" section for the convention) and prints a ledger grouped
# by file. A marker with no comma - no `, <upgrade path>` after the ceiling -
# is flagged as rot risk: a deliberate shortcut nobody wrote a trigger for.
#
# Only matches a comment-prefix immediately followed by "athene:" (#, //, or
# /*, optional single space) - a loose substring match on "athene:" catches
# this script's own source (strings/comments that mention the word without
# being a real marker) and false-positives on every hit. Markdown files are
# excluded entirely: a real marker lives in actual code, never in docs that
# just describe or show an example of the convention.
#
# git grep already skips .git and anything gitignored, so there's no separate
# exclude list to maintain here.
#
# Run from anywhere inside the repo to check - it does not have to be Athene's
# own; git grep finds the repo root itself.
#
# Usage: scripts/debt-ledger.sh
set -euo pipefail

matches="$(git grep -n -I --no-color -E '(#|//|/\*) ?athene:' -- ':!*.md' 2>/dev/null || true)"

if [ -z "$matches" ]; then
  echo "No athene: markers found."
  exit 0
fi

total=0
rot=0
current_file=""

while IFS= read -r line; do
  file="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  content="${rest#*:}"

  marker="${content#*athene:}"
  marker="$(printf '%s' "$marker" | sed 's/^[[:space:]]*//')"

  if [ "$file" != "$current_file" ]; then
    [ -n "$current_file" ] && echo
    echo "$file"
    current_file="$file"
  fi

  total=$((total + 1))
  if [[ "$marker" == *,* ]]; then
    echo "  $lineno: athene: $marker"
  else
    rot=$((rot + 1))
    echo "  $lineno: athene: $marker  [ROT RISK: no upgrade trigger named]"
  fi
done <<< "$matches"

echo
echo "$total marker(s), $rot flagged as rot risk."
