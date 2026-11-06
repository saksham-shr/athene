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
the findings where a reviewer actually looks: a PR comment. User-invoked, one PR at a time — not
a batch job and not a CI trigger.

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

Run both, don't guess at flags:
```
gh pr list --author @me
gh pr list --search "review-requested:@me"
```
These are two different relationships (yours vs. requested of you) — show both lists, labeled,
so the user knows which is which.

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

- **Map first, diff-scoped:** `gh pr diff <number>` for the changed lines; read enough
  surrounding code to trace each changed flow end to end — where the changed data comes in, what
  it touches, what goes out. Not the whole repo: only what the diff's flows actually pass
  through. Say what wasn't read.
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

Post via:
```
gh pr comment <number> --body "..."
```

Open the comment body with a disclosure line naming the tool and Athene as reviewer:

```
Reviewed by Athene (automated code-health review) via Claude Code.
```

(Decision, not left open: exact wording above — names the tool, names Athene, names what kind of
review it was, one line.)

This disclosure is deliberate and does **not** contradict this repo's own no-AI-attribution rule
(see `skills/athene/templates/CONTRIBUTING.md`'s "No AI attribution" section). That rule governs
a commit message or PR description trailer on work Athene *authors* — attribution there makes an
AI-written change look like it came with an invisible co-author riding along. A review comment is
a different case: the comment's entire content *is* the AI's review of someone else's work, posted
under a disclosed identity, not folded silently into another person's commit history. See
`docs/design/2026-10-31-athene-design.md`'s "External-repo personas" section for the underlying
disclosure-on-comment reasoning — don't re-derive it here.

Nothing found: post `Reviewed by Athene (automated code-health review) via <tool>. No findings —
diff looks healthy.` rather than skipping the comment.

One-shot review. Changes no code, posts one comment.
