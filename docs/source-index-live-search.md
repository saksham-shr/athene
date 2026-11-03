# Source-index live-search and issue-drafting flow

The flow `docs/engineering-source-index.md`'s "How this gets used" step 5 names but doesn't
fully spell out: what happens when a build decision's topic isn't in the curated index. Phase 4
of `docs/design/2026-10-31-athene-build-phases.md`. **Not yet wired into any skill:** `athene`,
the skill this feeds, doesn't exist in this repo yet — same structural gap as
`docs/stack-decision-process.md` and `docs/connector-detection.md` before them.

## When this triggers

A build decision's topic has no row in `docs/engineering-source-index.md`'s table. Don't skip
evidence and decide from memory — search live, following the same evidence bar the curated
entries hold themselves to.

## Judging a live-search result

Hold it to the same bar as a curated entry, not a lower one just because it was found on the
fly:
- **Primary source, not a reseller of the claim.** The team that actually built/operates the
  thing, not a marketing blog, SEO content farm, or a tutorial site repackaging someone else's
  post. If the result is itself citing another source, go find that source instead.
- **A specific, checkable claim** — a number, an architecture decision, a named failure mode —
  not generic "best practices" prose that could apply to anything.
- **Dated**, and not stale unless it's a still-cited foundational piece (e.g. the kind of paper
  or post the field still references years later). A 2019 post about a since-replaced service is
  weak evidence for a 2026 decision.
- **Corroborated** if the claim is surprising or counter to common practice — find a second
  source before citing a single outlier as settled.

## Extracting evidence

Same as an existing index entry: pull the specific post/page and the specific claim it makes —
not just "the domain is reputable." Cite the actual URL in the decision record, per
`docs/stack-decision-process.md`'s "Recording the decision" rule.

## Drafting the issue — real template, not "open an issue"

Title: `docs(source-index): propose adding <source name> for <topic>` (matches this repo's own
Conventional Commits + scope convention).

Body:
```
**Context**
Build decision on [topic] had no entry in docs/engineering-source-index.md. Found [source name]
while searching live for this build.

**Proposed source**
- Name: <source name>
- Topic: <topic — match an existing table row's topic name if it fits, or name a new one>
- URL: <the specific post/page used as evidence, not just the domain>
- RSS feed (if one exists): <feed URL, same convention as existing entries>
- Why: <one or two sentences — what makes this a primary source worth adding permanently, not
  just evidence good enough for this one decision>

**Depends on:** none
```

Per the existing rule in `docs/engineering-source-index.md`: don't silently append the new
source to the shared file — open this issue and let a maintainer (or the user, self-assigning)
decide whether it's added. The build decision itself proceeds using the live-search result as
one-off evidence; it doesn't wait on the issue being resolved.

## Cross-repo write access

An agent running inside someone else's target repo doesn't have credentials to file an issue
against Athene's own repo by default — this is a real constraint, not a local file edit.

**Concrete answer:** ask the user for a GitHub token scoped to create issues on Athene's repo —
a fine-grained PAT with `Issues: write`, **and** the user's own access to that repo actually
granted on the token (a fine-grained PAT can be limited to repos the token's owner has access
to; `Issues: write` alone doesn't guarantee that access exists). Never ask for a broader token.
Use it only for one explicit, non-interactive call. Set `GH_TOKEN` in the executor's own
environment for that call — never inline the token's value in the command text itself, it would
land in shell history and process listings. Pass the title/body directly so `gh` never prompts
(an agent without an interactive terminal would otherwise block waiting for input it can't give):

```
gh issue create --repo saksham-shr/athene \
  --title "docs(source-index): propose adding <source name> for <topic>" \
  --body-file -
```

(pipe the drafted body in via stdin, or `--body "<text>"` for a short one). Always pass `--repo`
explicitly; never rely on `gh`'s ambient default, which resolves to whatever repo the agent
happens to be running in — the *target* repo, not Athene's — and would file the issue in the
wrong place. `saksham-shr/athene` is the current Athene repo; update this if the project ever
moves. Don't write the token to any file in the target repo, don't log it, don't reuse it for
anything else. If the user declines, has no such token, or the token lacks real access to
Athene's repo:
- Don't drop the proposal silently. Give the user the fully-drafted issue body directly in the
  conversation so they can file it themselves (or decline to), and note in `.athene/state.md`'s
  Open questions that a source proposal is pending, with what topic it's for.

## Worked example — unindexed topic

Build decision: "pick a rate-limiting strategy for the API." No `rate limiting` row in
`docs/engineering-source-index.md`.

1. Options table first (per `docs/stack-decision-process.md` — this isn't optional just because
   the topic is unindexed):

   | Candidate | Pros | Cons |
   |---|---|---|
   | Token bucket | Allows short bursts, smooths out over time | Slightly more state per client than a fixed window |
   | Fixed window | Simplest to implement and reason about | Allows a burst right at the window boundary (2x the limit in a short span) |
   | Leaky bucket | Outputs at a constant, predictable rate | Without a burst-capacity variant, no short bursts at all — worse UX for bursty-but-legitimate traffic |

   (General algorithmic tradeoffs, not live-search citations — none of these three rows claims
   a specific source yet. Step 2 below is what actually supplies sourced evidence, and only for
   the row it covers.)

2. Live search finds [Stripe's rate limiters post](https://stripe.com/blog/rate-limiters) (Paul
   Tarjan, 2017) — a primary source (Stripe's own engineering blog), with a specific, checkable
   claim: "We use the token bucket algorithm to do rate limiting" — a central bucket per user,
   each request consumes a token, tokens refill gradually. Not a comparison against the other
   candidates above, so don't cite it as one — just cite the specific claim it actually makes,
   as evidence for picking the row already in the table.
3. Decision recorded (per `docs/stack-decision-process.md`) — cite only what the source actually
   supports, not a comparison it never made: *"Rate limiting: token bucket — Stripe's own
   engineering blog describes using this approach for their API, per
   https://stripe.com/blog/rate-limiters. Fixed window and leaky bucket weren't ruled out by any
   sourced evidence, just by the general tradeoffs in the table above; revisit if a real source
   favoring one of them turns up."*
4. Issue drafted proposing Stripe's blog be added under a new `rate limiting` topic row (Stripe
   is already in the index under `payments` — this is a second topic for an existing source, not
   a brand-new one, worth noting in the issue's Why field).
5. User has no token handy — issue body handed to them directly in chat, state.md's Open
   questions notes: "Source proposal pending (Stripe blog, rate limiting topic) — user to file or
   decline."
