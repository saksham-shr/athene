# Engineering source index

The curated reference file skill 2 (Athene build) consults at every nontrivial
build decision, per the design doc's "Evidence-backed architecture" section.
Seeded from [kilimchoi/engineering-blogs](https://github.com/kilimchoi/engineering-blogs)
(~218 company blogs, flat/alphabetical, no topic tags in the source repo) plus
AWS Builders' Library, mapped to topics by hand below. Each entry carries its
RSS feed URL, pulled from that repo's `engineering_blogs.opml` — real feed
URLs, not just blog homepages, so the skill can actually pull and read recent
posts rather than assume what a company blog probably says.

## How this gets used

Don't guess at a design decision. At each nontrivial build decision:
1. Identify the topic (payments, auth, search, etc.) from the table below.
2. Pull the matching feed(s) — fetch the RSS/atom feed, not just the HTML
   page, so the agent sees actual recent post titles/links to read.
3. Read the posts relevant to the specific decision at hand, not the whole
   feed history.
4. Cite what was actually found in the ADR-style decision note (problem →
   options/tradeoffs → decision), with a link to the specific post used as
   evidence — not a vague "best practices say."
5. If no entry below covers the topic needed, search live for it instead of
   skipping evidence — then follow the existing rule: don't silently add the
   new source to this file, open an issue on Athene's own repo proposing it.

## Topic map

| Topic | Source | RSS feed | Why |
|---|---|---|---|
| Payments | Stripe | https://stripe.com/blog/feed.rss | Primary payments-at-scale engineering blog. |
| Payments | Square | https://corner.squareup.com/blog/rss.xml | Payments + point-of-sale infra. |
| Payments | GoCardless | https://gocardless.com/content-platform/rss/resources.xml | Recurring-payments specific engineering. |
| Auth / identity | Auth0 | https://auth0.com/blog/rss.xml | Auth-as-a-service, dedicated identity engineering content. |
| Auth / identity | Okta | https://developer.okta.com/feed.xml | Identity/access management at scale. |
| Ecommerce / commerce | Shopify | https://shopify.engineering/blog.atom | Commerce platform at scale — the design doc's own example. |
| Ecommerce / commerce | OLX | https://tech.olx.com/feed | Marketplace engineering. |
| Marketplace / on-demand logistics | DoorDash | https://doordash.engineering/blog/rss | Real-time logistics/dispatch at scale. |
| Marketplace / on-demand logistics | Instacart | https://tech.instacart.com/feed | Marketplace + real-time inventory. |
| Marketplace / on-demand logistics | Deliveroo | https://deliveroo.engineering/feed.xml | Same domain, different scale/region tradeoffs. |
| Marketplace / on-demand logistics | Grab | http://engineering.grab.com/feed.xml | Super-app, multi-service marketplace at scale. |
| Social / feed systems | Instagram | https://instagram-engineering.com/feed | Feed ranking/serving at huge scale. |
| Social / feed systems | Pinterest | https://medium.com/feed/@Pinterest_Engineering | Discovery/recommendation feed systems. |
| Social / feed systems | Facebook | https://engineering.fb.com/feed/ | Largest-scale social graph/feed engineering. |
| Messaging / real-time | Slack | https://slack.engineering/rss | Real-time messaging infra at scale. |
| Messaging / real-time | Discord | https://discord.com/blog/rss.xml | Real-time voice/chat infra, different scale profile than Slack. |
| Messaging / queueing infra | Confluent | https://www.confluent.io/rss.xml | Kafka/event-streaming, written by the maintainers. |
| Search | Algolia | https://blog.algolia.com/blog/rss.xml | Search-as-a-service, latency-focused search engineering. |
| ML-serving / data platform | Databricks | https://www.databricks.com/feed | Data/ML platform engineering at scale. |
| ML-serving / data platform | Netflix | https://netflixtechblog.com/feed | Recommendation systems, ML infra, chaos engineering. |
| ML-serving / data platform | Spotify | https://engineering.atspotify.com/feed | Recommendation + data platform at consumer scale. |
| Distributed systems | Netflix | https://netflixtechblog.com/feed | Chaos engineering, resilience patterns at scale. |
| Distributed systems | Dropbox | https://dropbox.tech/feed | Storage/sync at scale, distributed-systems-heavy. |
| Distributed systems | AWS | https://aws.amazon.com/blogs/aws/feed/ | General AWS blog; prefer AWS Builders' Library (no feed, see below) first for depth. |
| CDN / latency / edge | Cloudflare | https://blog.cloudflare.com/rss | CDN, edge compute, network performance and security overlap. |
| Security | Cloudflare | https://blog.cloudflare.com/rss | DDoS, network security, edge security posture. |
| Security | Auth0 | https://auth0.com/blog/rss.xml | Auth-specific security engineering. |

**No feed (reference by URL, not RSS):**

| Topic | Source | URL | Why |
|---|---|---|---|
| Distributed systems | AWS Builders' Library | https://aws.amazon.com/builders-library/ | The design doc's own named source for this topic; Amazon senior engineers on timeouts/retries/backoff, distributed-systems failure modes. No RSS feed — check periodically instead. |

## Known gaps

The seed repo doesn't cover every topic the design doc or the engineering
quality-bar section calls for. No entry found for:
- **Server management / SRE / observability** — no Datadog, PagerDuty,
  Honeycomb, or New Relic blog in the seed list. Search live for this topic
  until a source is added.
- **General distributed-systems depth beyond AWS/Netflix/Dropbox** — no Uber,
  LinkedIn, or Twitter/X engineering blog in the seed list (all historically
  strong sources for this topic), likely because the seed repo is somewhat
  dated. Worth a live search or a PR adding them.

Per the existing rule: don't silently extend this file mid-build when a gap
is hit — open an issue on Athene's own repo proposing the addition.
