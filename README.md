# Athene

Skills that make an AI coding agent follow proper engineering practices — discover the right
thing to build, build it with real repo hygiene, launch small, learn, and resume or retrofit onto
any repo, old or new.

Design doc: [`docs/design/2026-10-31-athene-design.md`](docs/design/2026-10-31-athene-design.md).
Phase breakdown: [`docs/design/2026-10-31-athene-build-phases.md`](docs/design/2026-10-31-athene-build-phases.md).
Build happens issue-by-issue.

## Status

Phases 0–4 (repo scaffold, Resume/Audit, governance generation, stack-decision flow, self-growing
source index) are built and merged, along with the items from a prior-art review (Code Health
skill, `athene:` shortcut-comment convention, condensed bootstrap snippets). `athene`, the core
build skill, is now fully wired: lifecycle, ownership, CI/CD, stack decisions, evidence-backed
architecture, governance generation, the review gate, and Launch handoff (#35–#38).

## Skills

Live, in [`skills/`](skills/):
- **`athene-resume`** — picks up an Athene-tracked repo where it left off.
- **`athene-audit`** — onboards Athene onto an existing repo: scans it, determines project
  framing + risk tier, writes the right governance docs, offers a review-gate toggle.
- **`athene-code-health`** — ranked bug/security/scale/test/speed/lean audit of the code itself,
  distinct from `athene-audit`'s process-only scope. One-shot report, changes nothing.
- **`athene`** (skill 2, repo + build + architecture) — the core build skill: lifecycle, ownership,
  CI/CD, stack decisions, evidence-backed architecture + the engineering quality bar, governance
  generation, the review gate, and Launch handoff.
- **`athene-product-discovery`** (skill 1) — turns an ambiguous idea into an approved product
  brief, then hands off to `athene`. Core scaffold built; the Opportunity Solution Tree
  opportunity-scoring step and the discovery-specific anti-pattern list are still open follow-ups
  (#50, #51).

Planned, not yet built:
- **Athene: Launch** — define the smallest launchable slice, confirm release readiness.

## Reference specs

Consumed by a skill via `references/` include-marker stubs (see
[`docs/skill-packaging.md`](docs/skill-packaging.md)), not cross-cutting on their own:
- [`docs/governance-doc-set-mapping.md`](docs/governance-doc-set-mapping.md) — risk-tier × framing
  → governance doc set. Wired into `athene-audit` and `athene`.
- [`docs/review-gate.md`](docs/review-gate.md) + [`scripts/set-review-gate.sh`](scripts/set-review-gate.sh)
  — real branch-protection toggle. Wired into `athene-audit` and `athene`.
- [`docs/stack-decision-process.md`](docs/stack-decision-process.md) — options table + tier
  question format for build decisions. Wired into `athene`.
- [`docs/connector-detection.md`](docs/connector-detection.md) — MCP/connector detection and setup
  per platform. Wired into `athene`.
- [`docs/engineering-source-index.md`](docs/engineering-source-index.md) — topic-mapped real
  engineering blogs with RSS feeds, for evidence-backed decisions. Wired into `athene`.
- [`docs/source-index-live-search.md`](docs/source-index-live-search.md) — live-search fallback
  and issue-drafting flow for a topic the source index doesn't cover. Wired into `athene`.

Repository-wide maintainer documentation — not bundled via include-marker, not mirrored into any
skill:
- [`docs/state-schema.md`](docs/state-schema.md) — `.athene/state.md` schema.
- [`docs/skill-packaging.md`](docs/skill-packaging.md) — skill directory convention and the
  include-marker build step (`scripts/mirror-skills.sh`).
- [`docs/skill-description-style-guide.md`](docs/skill-description-style-guide.md) — how to write
  a skill's always-loaded description.

## Contributing

Conventional Commits types, PR template, issue templates: see
[`skills/athene-audit/templates/`](skills/athene-audit/templates/) — the same baseline Athene
writes into target repos.
