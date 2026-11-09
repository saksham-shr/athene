#!/usr/bin/env bash
# Greps the repo for real `athene:` shortcut markers (see CONTRIBUTING.md's
# "Shortcut markers" section for the convention) and prints a ledger grouped
# by file. A marker with no nonempty text after a comma - no real
# `, <upgrade path>` after the ceiling - is flagged as rot risk: a
# deliberate shortcut nobody wrote a trigger for.
#
# Only matches a comment-prefix immediately followed by "athene:" (#, //, or
# /*, optional single space) - a loose substring match on "athene:" catches
# this script's own source (strings/comments that mention the word without
# being a real marker) and false-positives on every hit. Markdown files and
# this script's own self-check fixture are excluded entirely: a real marker
# lives in actual code, never in docs describing the convention or in the
# planted examples debt-ledger-test.sh uses to test itself.
#
# Runs from the repo root regardless of the caller's cwd - plain `git grep`
# only searches the current directory and below, so invoking this from a
# subdirectory would silently miss markers elsewhere in the repo.
#
# Usage: scripts/debt-ledger.sh
set -euo pipefail

root="$(git rev-parse --show-toplevel)"

status=0
matches="$(cd "$root" && git grep --untracked --no-recurse-submodules -n -I --no-color \
  -E '(#|//|/\*) ?athene:' -- ':!*.md' ':!scripts/debt-ledger-test.sh')" || status=$?

# git grep exits 1 for "no matches" - that's a normal empty result, not an
# error. Any other nonzero status (e.g. --untracked conflicting with
# submodule.recurse=true) is a real failure and must stop the script, not be
# silently swallowed into a false "no markers found".
if [ "$status" -eq 1 ]; then
  matches=""
elif [ "$status" -ne 0 ]; then
  exit "$status"
fi

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
  # A marker inside a /* ... */ block comment has the closing delimiter and
  # anything after it still inside $marker - strip that before checking for
  # upgrade text, or trailing code reads as a valid upgrade path.
  if [[ "$content" =~ /\*[[:space:]]?athene: ]]; then
    marker="$(printf '%s' "$marker" | sed 's#[[:space:]]*\*/.*$##')"
  fi

  if [ "$file" != "$current_file" ]; then
    [ -n "$current_file" ] && echo
    echo "$file"
    current_file="$file"
  fi

  total=$((total + 1))
  upgrade="${marker#*,}"
  upgrade="$(printf '%s' "$upgrade" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ "$marker" == *,* ]] && [ -n "$upgrade" ]; then
    echo "  $lineno: athene: $marker"
  else
    rot=$((rot + 1))
    echo "  $lineno: athene: $marker  [ROT RISK: no upgrade trigger named]"
  fi
done <<< "$matches"

echo
echo "$total marker(s), $rot flagged as rot risk."
