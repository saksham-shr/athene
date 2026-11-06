---
name: athene-pr-review
description: >-
  Review one open GitHub PR you authored or are requested to review, and post findings as a real
  PR comment - bugs, security, scale, missing tests, speed, bloat, scoped to the diff. Use for
  "review this PR", "review my open PRs", "what's wrong with PR #N". Skip for a whole-repo audit
  (Athene: Code Health) or reviewing work before a PR exists (Athene's own self-review pass).
---

# Athene: PR Review

Review one already-open GitHub PR the way a senior reviewer would, scoped to its diff, and leave
the findings as a general PR conversation comment (`gh pr comment` — not an inline diff comment),
where a reviewer looking at the PR will still see it. User-invoked, one PR at a time — not a batch
job and not a CI trigger.

Distinct from two other things that look similar:
- **Athene: Code Health** reviews the whole repo, one-shot, and changes nothing — no PR
  awareness at all. This skill is the opposite scope: one PR's diff, not the repo.
- **Athene's own self-review subagent pass** (`skills/athene/SKILL.md`'s "Governance artifacts"
  section) runs *before* a PR exists, on a diff Athene itself is about to send for human review.
  This skill runs *after* a PR is already open on GitHub — someone else's PR, or one the user
  already opened and wants a second pass on — and it posts its findings as a visible comment
  instead of folding them into the diff before it's sent.

Reuses Code Health's six finding categories and 4-part finding format, adapted from whole-repo
scope to diff scope. Code Health itself is unchanged by this skill — don't edit it.

## 1. Fetch candidate PRs

Run both, don't guess at flags, and don't rely on the default page size — `gh pr list` returns at
most 30 PRs per call, silently omitting older matches past that:
```
gh pr list --author @me --limit 200
gh pr list --search "review-requested:@me" --limit 200
```
These are two different relationships (yours vs. requested of you) — show both lists, labeled,
so the user knows which is which. `--limit 200` is a practical ceiling, not a guarantee every
possible PR is covered — if either list comes back exactly at the limit, say so, since that's a
sign there may be more.

## 2. Let the user pick one

Show the combined list (number, title, author) and ask which one to review. Review exactly one
PR per run — this skill is user-invoked and user-picked, not an automatic batch sweep over every
open PR. (Decision, not left open: issue #85 names "single vs. batch" as an open, non-blocking
question; single-PR-per-run is the call here, because #85's own proposal text says "let the user
pick one," which only makes sense for one PR at a time.)

## 3. Review scoped to the diff, in a subagent

Don't read the diff and trace the flow in the main thread — dispatch a subagent (or fork) to do
the actual read-and-review work, then return findings. A full diff plus the code it touches is
exactly the kind of context-budget load that belongs isolated from the thread doing the PR-
picking and comment-posting work, not absorbed into it.

Give the subagent the PR number and this scope:

- **Pin the PR head and base commit before reading anything else.** `gh pr diff <number>` doesn't
  check out the PR — it diffs against whatever ref `gh` resolves, independent of the local working
  tree's current branch. Resolve the PR's head commit and base *commit* first via the REST API,
  not `gh pr view --json`: `gh api repos/{owner}/{repo}/pulls/<number> --jq '{head: .head.sha,
  base: .base.sha}'` (`gh api` reads the GitHub REST API's `pulls` object directly — `head.sha` /
  `base.sha` have been stable fields on that object for years; `gh pr view --json baseRefOid`
  needs a recent `gh` CLI release the caller's environment may not have, so query the API
  directly instead of depending on `gh`'s own `--json` field coverage). The base commit, not just
  `base.ref` (the branch name): the base branch name can stay `main` while `main` itself keeps
  advancing underneath the PR, so the branch name alone doesn't catch that. Read all surrounding
  code at that exact pinned head commit (e.g. `git show <headRefOid>:<path>`), never off the
  caller's current checkout — if the user is on a different branch locally, reading files straight
  off disk traces stale code and produces wrong findings or a false "no findings" comment. Pinning
  the base commit matters for a second reason beyond a retarget: even with no retarget, the base
  can advance in a way the diff doesn't show — e.g. the PR adds a call to `f(x)` while the base
  separately changes `f` to require a second argument; the merge can succeed with no conflict, but
  the code the PR actually adds would fail post-merge, and a head-only read reports it as fine.
  Where feasible, also check the changed flows against what the PR would look like merged onto the
  pinned base commit, not just the head commit in isolation. Confirm the diff and every
  surrounding-code read reference the same pinned head and base before reporting anything.
- **Map first, diff-scoped:** `gh pr diff <number>` for the changed lines; read enough
  surrounding code (at the pinned head above) to trace each changed flow end to end — where the
  changed data comes in, what it touches, what goes out. Not the whole repo: only what the diff's
  flows actually pass through. Say what wasn't read.
- **Look for**, same six categories as Code Health, same meaning, applied to what changed:
  1. **Bug** — wrong result, crash, missed edge case, callers that disagree with what the
     changed function actually returns.
  2. **Risk** — security holes, data loss, missing checks on user input the diff introduces or
     touches.
  3. **Scale** — fine for one user, wrong for many, introduced or made worse by this diff.
  4. **Missing test** — risky logic in the diff (a branch, a parser, money, security, data
     writes) with no test that fails when it breaks.
  5. **Speed** — a real slowdown the diff introduces; a small win is a suggestion, not a
     must-fix.
  6. **Lean** — code in the diff that shouldn't exist, duplicates something already there, or
     adds a comment that fails Code Health's own comment proof-test (explains the fix itself,
     restates the line below it, or carries no proof of a genuine external constraint).
- **Check before reporting**, same as Code Health: every finding needs a concrete case; no style
  taste, no vague "consider," no finding without one.

## 4. Comment format: compact, not narrative

Code Health's plain-English numbered block was built for a standalone report someone reads top
to bottom. A PR comment is read inline, next to the diff it's about — so this skill uses a
compact format instead (decision, not left open: issue #85 names this as open):

```
file:line: severity: problem. fix.
```

One line per finding, severity one of `must-fix` / `should-fix` / `nice-to-have`, grouped in that
order, blank line between groups. No four-part prose block, no restating the diff. Example:

```
Must fix:
billing/close_day.py:47: must-fix: closes the day using the server's UTC clock, so a Berlin
order placed at 00:30 bills a day early. Compute the day in the shop's time zone once.

Should fix:
api/routes.py:112: should-fix: new endpoint has no test for the empty-list input it explicitly
handles. One test covering that branch.
```

Cap at 20 findings; if more were found, say how many were left out, same as Code Health.

## 5. Post the comment, with disclosure

Before posting, re-check the PR's current head and base commit (same `gh api
repos/{owner}/{repo}/pulls/<number> --jq '{head: .head.sha, base: .base.sha}'` call as step 3)
against what was pinned there. A head change means new commits landed; a base-commit change means
either a retarget to a
different branch or the existing base branch advancing underneath the PR — either way the diff the
findings describe may no longer be the PR's actual diff, even if the head commit itself didn't
move. Don't post as if nothing happened: tell the user what changed and either restart against the
new head/base or post with that gap stated plainly, whichever they'd rather have.

Write the comment body to a file first, then post it from the file — never interpolate findings
text (file paths, code snippets, PR title/description) into a double-quoted shell string. A PR can
legitimately contain a filename or diff line shaped like `$(id)` or backticked shell syntax; a
shell building the comment from a quoted string would execute it while posting instead of treating
it as literal text.
```
gh pr comment <number> --body-file <path-to-written-file>
```

Open the comment body with a disclosure line naming the tool, Athene as reviewer, and the exact
commit reviewed:

```
Reviewed by Athene (automated code-health review) via <tool>, against <headRefOid>.
```

`<tool>` is whichever agent is actually running this skill — Claude Code, Codex, or Cursor — not
a hardcoded name. This skill is packaged for all three (see `docs/skill-packaging.md`); a Codex
or Cursor run claiming "via Claude Code" would misstate who actually reviewed the PR.

`<headRefOid>` is the exact commit SHA the findings below are about — the one pinned in step 3 and
reconfirmed at the top of this step. Naming it means a reader can tell, from the comment alone,
whether it's still describing the PR's current state or was left behind by a later push; without
it, a stale "no findings" comment reads as current when it isn't. (Decision, not left open: the
line's shape — tool, Athene, review kind, reviewed commit, one line — is fixed; only `<tool>` and
`<headRefOid>` vary.)

This disclosure is deliberate and does **not** contradict this repo's own no-AI-attribution rule
(see `skills/athene/templates/CONTRIBUTING.md`'s "No AI attribution" section). That rule governs
a commit message or PR description trailer on work Athene *authors* — attribution there makes an
AI-written change look like it came with an invisible co-author riding along. A review comment is
a different case: the comment's entire content *is* the AI's review of someone else's work, posted
under a disclosed identity, not folded silently into another person's commit history. See
`docs/design/2026-10-31-athene-design.md`'s "External-repo personas" section for the underlying
disclosure-on-comment reasoning — don't re-derive it here.

**Disclose unread scope whenever it exists — whether or not findings were posted.** If anything
from "Say what wasn't read" in step 3 above applies (a file too large, access denied, a
surrounding-code path that couldn't be resolved), name it in the comment regardless of outcome. A
reader seeing findings for the files that *were* read can otherwise mistake a partial review for a
complete one just as easily as a "no findings" comment can read as "confirmed clean."

Nothing found, and every changed file plus its surrounding code was actually read: post `Reviewed
by Athene (automated code-health review) via <tool>, against <headRefOid>. No findings — diff
looks healthy.` rather than skipping the comment.

Nothing found, but something couldn't be read: don't claim healthy. Post the same disclosure line,
then name exactly what wasn't read instead of "diff looks healthy" — an unreviewed file reported as
clean is worse than no comment at all.

Findings were posted, but something else in the diff couldn't be read: list the findings as usual,
then add what wasn't read as its own line in the same comment — don't let real findings crowd out
the disclosure just because there's already content in the comment.

One-shot review. Changes no code, posts one comment.
