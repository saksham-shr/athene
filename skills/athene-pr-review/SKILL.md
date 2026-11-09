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
   `.diff` URL) for the diff, and `https://api.github.com/repos/<owner>/<repo>/pulls/<number>`
   (also unauthenticated, rate-limited, for public repos) for its `state`, `head.sha`, and
   `base.ref` — step 3 below needs those. Reads nothing from the user's machine.
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
4. **Still nothing:** ask the user to paste the diff directly, and ask them to also confirm the
   PR's current open/closed state, head SHA, and base branch at the same time — this path has no
   other way to get those values, and step 3 below needs them. This path has no way to verify the
   pasted text is the complete diff either — treat the reviewed scope as unverified in step 5's
   disclosure rather than claiming "diff looks healthy" on a result this skill can't confirm is
   whole, and treat the head SHA disclosed in the comment as unverified too unless the user
   reconfirms it immediately before posting (step 6).

Also read whatever surrounding code the diff references, same as any code review — don't judge a
changed line in isolation.

## 3. Check the head and base before posting

Record the PR's head SHA and base branch alongside the diff when fetching it in step 2 — from the
fetch response, the MCP tool's result, or, on the paste path, the values the user supplied. Right
before drafting the comment, re-check both — a base-branch update can change the diff without
changing the head SHA. On the paste path, "re-check" means asking the user to reconfirm both
values, since there's no API call to re-fetch from. Either changed: re-fetch (or re-ask) and
re-review the diff before drafting; never comment against a diff that's gone stale.

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
- Nothing found, and everything changed was actually read from a source that confirms full
  coverage (fetched diff, not a pasted one): "No findings — diff looks healthy."
- Nothing found, but something couldn't be read, or the diff came from step 2.4's paste fallback
  with no way to confirm it's complete: don't claim healthy — say the reviewed scope is
  unverified, or name what wasn't read. An unreviewed file reported as clean is worse than no
  comment.
- Findings were posted, but something else in the diff couldn't be read: list the findings as
  usual, then add what wasn't read as its own line — don't let real findings crowd it out.

## 6. Post — only after explicit yes, one comment, one time

Re-check both the head SHA and the base branch one more time right here, immediately before
posting — time passed during step 5's confirmation, and a retarget can change the diff without
changing the head. Either changed: go back to step 4 with the new diff and get confirmation again
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
