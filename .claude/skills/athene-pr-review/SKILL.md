---
name: athene-pr-review
description: >-
  Review one open PR the user names and leave a single disclosed comment on it. Only runs when
  asked, on exactly one PR at a time. Never batches, approves, merges, or changes branch settings.
  Skip for a whole-repo report (use Athene: Code Health) or any PR the user hasn't picked.
---

# Athene: PR Review

Give one named, open pull request the same quality bar as Athene: Code Health, scoped to just
that PR's diff, then post the result as one ordinary PR comment — only after the user confirms
the exact text.

**Never:** touch a second PR in the same run, approve, merge, request changes as a formal review
state, trigger CI, or change branch/repo settings. One diff in, one comment out.

## 1. Which PR

Ask if not already named: repo (`owner/repo`) and PR number, or a PR URL containing both. Confirm
it's still open before reading it — don't review a PR that's already closed or merged.

## 2. Get the diff — try in this order, stop at the first that works

1. **Public repo, no credential needed:** fetch
   `https://patch-diff.githubusercontent.com/raw/<owner>/<repo>/pull/<number>.diff` (or the PR's
   `.diff` URL) directly. Works for any public repo, reads nothing from the user's machine.
2. **A GitHub MCP server is configured:** check per `references/connector-detection.md` in this
   skill. If present, use its PR-read tool instead of step 1 or 3 — it already carries whatever
   auth it needs, this skill never touches that credential directly.
3. **Private repo and no MCP server, or step 1 returned 404/403:** tell the user step 1/2 didn't
   work and ask to run `gh pr diff <number> -R <owner>/<repo>` using **their own
   already-authenticated `gh` session** — name the exact command before running it, run it only
   after they say yes. `-R <owner>/<repo>` is required so the command works even when run outside
   a clone of the target repo. This skill never reads, stores, or forwards a GitHub token itself;
   `gh` handles its own auth outside this skill entirely, and each use is a fresh, visible,
   user-approved command, not a stored credential or a bundled script.
4. **Still nothing:** ask the user to paste the diff directly.

Also read whatever surrounding code the diff references, same as any code review — don't judge a
changed line in isolation.

## 3. Check the head and base before posting

Record the PR's head SHA and base branch alongside the diff when fetching it in step 2. Right
before drafting the comment, re-check both — a base-branch update can change the diff without
changing the head SHA. If either changed, re-fetch the diff and re-review it before drafting;
never comment against a diff that's gone stale.

## 4. Review, scoped to the diff

Same bar as Athene: Code Health — order of importance: correct, safe, holds under load, tested,
fast, lean. Look for: bugs (wrong result, crash, missed edge case), security/data-loss risk,
scale problems the diff introduces, risky new logic with no test, a real slowdown, and anything
that shouldn't exist (dead code, needless duplication, an abstraction the diff doesn't need).
Every finding needs a concrete failure case — no case, no finding. Comment only on what the diff
actually changed; a pre-existing problem elsewhere in the file is out of scope unless the diff
makes it worse.

## 5. Draft, show, confirm

Write the comment as plain English findings (same four-part shape as Code Health: what, problem,
fix, if skipped), opening with one line disclosing it's an automated review from Athene and the
commit SHA reviewed. Show the full exact text to the user before posting anything. Nothing found:
a short "Looks good" comment is still shown for confirmation, not skipped silently — the user may
prefer no comment at all in that case, so ask.

**Disclose unread scope whenever it exists — whether or not findings were posted.** A file too
large to fetch, an access-denied path, or surrounding code that couldn't be resolved: name it in
the comment regardless of outcome.
- Nothing found, and everything changed was actually read: "No findings — diff looks healthy."
- Nothing found, but something couldn't be read: don't claim healthy — name what wasn't read
  instead of "looks healthy." An unreviewed file reported as clean is worse than no comment.
- Findings were posted, but something else in the diff couldn't be read: list the findings as
  usual, then add what wasn't read as its own line — don't let real findings crowd it out.

## 6. Post — only after explicit yes, one comment, one time

Re-check the head SHA one more time right here, immediately before posting — time passed during
step 5's confirmation. Changed: go back to step 4 with the new diff and get confirmation again
before posting anything.

- MCP server from step 2: use its comment-post tool.
- Otherwise: show the exact comment text and the exact command, then run
  `gh pr comment <number> -R <owner>/<repo> --body-file -` with the comment text supplied on
  stdin, run only on explicit confirmation. Never interpolate the comment text into a shell
  command string (`--body "<text>"`) — text containing `` ` `` or `$(...)` would execute as shell
  code; `--body-file -` with piped stdin passes it as data instead.
- No path available (no MCP, no `gh`, user declines): give the user the exact comment text to
  post themselves and stop there. Don't fall back to any other write path.

Post once. If the user wants changes, redo steps 4-5 and ask again before any second post attempt.
