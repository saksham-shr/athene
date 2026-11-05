---
name: athene-launch
description: >-
  Prepare a product or feature for an early, evidence-seeking launch: cut scope to the smallest
  learning release, validate the riskiest assumptions, define release readiness, and run the
  post-launch review. Use when the user is preparing to launch, validate, beta-test, announce, or
  market a product/feature. Counters feature accumulation - prioritize a fast, safe learning loop
  over a larger build.
---

# Athene: Launch

Use this skill when the user is preparing to launch, validate, beta-test, announce, or market a
product/feature. Designed to counter feature accumulation: prioritize a fast, safe learning loop
over a larger build.

## Start with the launch question

Establish the smallest decision the launch should inform. Examples: "Will this audience sign
up?", "Can they complete the core job?", "Will they return or pay?", "Can we operate this
safely?"

Identify:

- target audience and their concrete problem;
- promised outcome and the smallest end-to-end experience that demonstrates it;
- current evidence, strongest assumption, and invalidating result;
- launch constraints: time, capacity, privacy, legal/compliance, support, reliability, budget,
  and brand risk.

If the answer is unclear, ask one high-leverage question or propose a testable assumption. Don't
let feature requests substitute for a launch hypothesis.

## Cut to a launchable slice

Define a minimum lovable/viable *learning* release: enough for a real person to achieve the core
outcome, no more. Write `now`, `after evidence`, and `not for this launch` lists. Challenge
additions with:

> Does this increase our ability to learn the launch question, or merely make the product feel
> more complete?

Prefer manual operations, concierge onboarding, a waitlist, prototype, limited geography/
audience, feature flag, or invite-only beta when they test the hypothesis faster and safely. Be
explicit about temporary/manual steps and their owner; don't disguise them as scalable product
capability.

## Choose validation and metrics

Pair each important assumption with an observable signal and a threshold or decision rule. Use
leading signals first:

| Assumption | Useful evidence | Decision example |
|---|---|---|
| Problem matters | Interviews, repeated behavior, waitlist conversion | Continue only if target users describe the pain and seek a solution without prompting. |
| Value is understood | Landing-page comprehension, demo, onboarding completion | Revise positioning/onboarding if users can't explain the benefit. |
| Core workflow works | Task success, time to first value, support friction | Fix the workflow before adding secondary features. |
| Demand is real | Qualified sign-ups, activation, repeat use, willingness to pay | Scale acquisition only after meaningful activation/retention evidence. |
| Operations are safe | Error/incident rate, support load, rollback test, privacy/security checks | Limit cohort or pause if the risk budget is exceeded. |

Avoid vanity metrics. Measure a behavior close to delivered value, segment by intended audience/
source, and record sample size, caveats, and qualitative feedback. Don't claim validation from
friend/employee praise, impressions alone, or an unsegmented visitor count.

**Launch-day traffic is a feedback spike, not a retention channel.** A Product Hunt/Show HN-style
launch-day number measures attention, not any of the assumptions in the table above. Respond to
comments and validate which pain-point language resonates first; then prioritize testing
niche/community channels. 100 real signups that convert beats 1,000 upvotes that convert nobody
— don't record the raw spike number itself as validation for "demand is real."

## Build the launch plan

Create a concise plan with:

```text
Launch hypothesis and target cohort
Core promise, proof, and call to action
Scope: launch / deferred / explicitly excluded
Positioning: audience, painful alternative, differentiated outcome, honest limitations
Channels and assets: where the cohort already pays attention and what each needs
Launch sequence: pre-launch, opening, first 72 hours, follow-up
Instrumentation and dashboard: activation, retention, conversion, quality/support signals
Readiness: quality, privacy/security, legal, accessibility, support, incident/rollback owner
Decision options: continue / change positioning-onboarding / fix the core workflow / test a new
  hypothesis / expand the cohort / stop
Review window: when the decision above gets made (ties to "Learn, decide, repeat" below)
```

**Choose channels with the Bullseye Framework** (Gabriel Weinberg, *Traction*), not by picking
whichever one comes to mind first:
1. **Brainstorm** all 19 traction channels — viral marketing, PR, unconventional PR, SEM, social/
   display ads, offline ads, SEO, content marketing, email marketing, engineering as marketing,
   business development, sales, affiliate programs, existing platforms, trade shows, offline
   events, speaking engagements, community building, targeting blogs — sketch how each could
   plausibly work for *this* product, including unlikely-looking ones.
2. **Test** the top 3-5 cheaply for real signal before committing real time or money.
3. **Focus** resources on whichever one channel clearly outperforms; stop spreading effort thin
   across several.

**Prefilter by audience type before brainstorming** — not a replacement for the three steps
above, a better starting point for step 1: a developer/B2B audience weights the brainstorm toward
X/Twitter + community-building + sales/business development; a consumer/visual-product audience
weights it toward short-form video + existing platforms (Product Hunt-style).

Match the asset to the channel chosen: a landing page/demo for discovery, onboarding/email for
activation, a case study or testimonial only with truthful consent, release notes/community post
for existing users. Write claims that can be supported by current evidence; never invent urgency,
customer quotes, performance results, or security guarantees.

**Treat case studies as illustrative tactics, not a comparable benchmark** when setting an
expected-outcome range. Real launches measure different things (users, signups, referral growth,
waitlist emails) over different time windows — don't blend them into one range. Use the one
same-metric, same-window source that actually supports a given range, and carry forward any
self-reported-figures caveat rather than presenting a secondhand number as verified fact.

**Store the launch plan locally, not in the target repo.** Write it to
`~/.athene/<repo-slug>/launch-plans/<timestamp>-<topic-slug>.md` — local-only, uncommitted, not
synced anywhere (same pattern as `athene-product-discovery`'s brief storage and the design doc's
"Discovery brief / Launch plan storage" decision). `<repo-slug>` derivation (folder name, or a
hash if collisions matter) is left to the builder. Record the plan and this file's path — not
its full content — in `.athene/state.md`'s Decisions made.

## Release responsibly

Use the smallest suitable delivery control: internal preview, design partners, invite-only beta,
gradual rollout, or general availability. Define admission, support hours, feedback path,
monitoring, pause/rollback authority, and user communication before opening access.

Before launch, confirm:

- the primary journey works for the intended cohort;
- analytics/events respect privacy and answer the launch question;
- errors, support requests, refunds/cancellation, and incident escalation have owners;
- the deployed artifact/config can be identified and rolled back or rolled forward;
- marketing claims, pricing, and eligibility match the product users receive;
- known limitations are visible to affected users.

Use `athene` for production-release mechanics, security, CI/CD, versioning, and rollback design.
Use `athene-product-discovery` when the audience, problem, or product shape is still unresolved.

## Learn, decide, repeat

Within a pre-agreed review window, synthesize quantitative signals and direct user evidence.
Compare outcomes to the hypothesis, not to a desire for the project to succeed. Choose one of:
continue the current wedge, change positioning/onboarding, fix the core workflow, test a new
hypothesis, expand the cohort, or stop. Publish the decision and the evidence internally so the
next roadmap step is earned by learning rather than momentum.

## State handling

Create or update `.athene/state.md` as a committed plain-Markdown file, self-contained spec below
(this file doesn't travel with the skill once mirrored elsewhere, so don't cross-reference it by
path). Write it at the end of this skill's turn/session, not mid-task:

- Four headings, in this exact order, each required — `none`/`n/a` rather than omitting one:
  `## Active skill`, `## Current phase`, `## Decisions made`, `## Open questions`.
- **Active skill:** `athene-launch` — this skill's own frontmatter `name`, while this skill owns
  the repo. Set to `athene-product-discovery`'s frontmatter name only on the pivot/new-hypothesis
  handoff below (otherwise the cycle ends here and no handoff happens at all).
- **Current phase:** one of this skill's own stages above (`launch-question`, `cut-scope`,
  `validation-metrics`, `launch-plan`, `release`, `learn-decide`), while `Active skill` is
  `athene-launch`.
- **Decisions made:** bullet list, append-only. What was chosen and why, in the order decided —
  the launch hypothesis, scope cuts, channel choices, and the final decision from "Learn, decide,
  repeat" below (continue / change positioning-onboarding / fix the core workflow / test a new
  hypothesis / expand the cohort / stop).
- **Open questions:** bullet list. Anything genuinely unresolved. `none` if nothing's outstanding.

## Handoff

"Learn, decide, repeat" above ends in one of six decisions. Only **test a new hypothesis** is a
handoff — the other five (continue, change positioning/onboarding, fix the core workflow, expand
the cohort, stop) end this cycle without handing off anywhere; record the decision in Decisions
made and stop there.

For a new-hypothesis handoff: confirm the `athene-product-discovery` skill file is packaged
where this skill is installed. If it isn't, say so explicitly and stop there rather than claiming
a handoff that can't happen, instead of guessing at Discovery's behavior.

If it is packaged, update `.athene/state.md`: set `Active skill` to `athene-product-discovery`
and `Current phase` to `handoff` — the shared reserved value both skills agree means "just
arrived, haven't started your own stages yet," not one of this skill's own phase names. Then read
and follow the `athene-product-discovery` skill file directly — a plain read-and-follow
instruction, not a platform-specific invoke call.
