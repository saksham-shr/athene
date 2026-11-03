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
build skill, is now scaffolded (trigger, lifecycle, state handling, Launch handoff) but doesn't
yet consume the specs below — wiring those in is the current work (#36, #37, #38).

## Skills

Live, in [`skills/`](skills/):
- **`athene-resume`** — picks up an Athene-tracked repo where it left off.
- **`athene-audit`** — onboards Athene onto an existing repo: scans it, determines project
  framing + risk tier, writes the right governance docs, offers a review-gate toggle.
- **`athene-code-health`** — ranked bug/security/scale/test/speed/lean audit of the code itself,
  distinct from `athene-audit`'s process-only scope. One-shot report, changes nothing.
- **`athene`** (skill 2, repo + build + architecture) — the core build skill: lifecycle, ownership,
  CI/CD, Launch handoff. Scaffolded; stack decisions, evidence-backed architecture, the
  engineering quality bar, governance generation, and the review gate are specced (see below) but
  not yet wired in.

Planned, not yet built:
- **Athene: Product Discovery**, **Athene: Launch** — turn an idea into a brief, and define the
  smallest launchable slice.

## Reference specs (not yet wired into a skill)

- [`docs/governance-doc-set-mapping.md`](docs/governance-doc-set-mapping.md) — risk-tier × framing
  → governance doc set.
- [`docs/review-gate.md`](docs/review-gate.md) + [`scripts/set-review-gate.sh`](scripts/set-review-gate.sh)
  — real branch-protection toggle.
- [`docs/stack-decision-process.md`](docs/stack-decision-process.md) — options table + tier
  question format for build decisions.
- [`docs/connector-detection.md`](docs/connector-detection.md) — MCP/connector detection and setup
  per platform.
- [`docs/engineering-source-index.md`](docs/engineering-source-index.md) — topic-mapped real
  engineering blogs with RSS feeds, for evidence-backed decisions.
- [`docs/source-index-live-search.md`](docs/source-index-live-search.md) — live-search fallback
  and issue-drafting flow for a topic the source index doesn't cover.
- [`docs/state-schema.md`](docs/state-schema.md) — `.athene/state.md` schema.
- [`docs/skill-packaging.md`](docs/skill-packaging.md) — skill directory convention and the
  include-marker build step (`scripts/mirror-skills.sh`).
- [`docs/skill-description-style-guide.md`](docs/skill-description-style-guide.md) — how to write
  a skill's always-loaded description.

## Contributing

Conventional Commits types, PR template, issue templates: see
[`skills/athene-audit/templates/`](skills/athene-audit/templates/) — the same baseline Athene
writes into target repos.
