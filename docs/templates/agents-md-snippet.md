## Athene bootstrap

Before doing anything else this session, check for `.athene/state.md` in this repo.

- **Found** → read it, then follow the Athene: Resume skill.
- **Not found**, and the user is asking to build/ship something → follow the
  Athene: Audit skill first, not Discovery or Build directly.

At every nontrivial build decision, regardless of which skill is active:
- Write a short problem → options/tradeoffs → decision → consequences note (skip the
  full note if the choice is reversible in under a week — decide fast instead).
- State requirements as measurable targets ("under 200ms"), not vibes ("fast").
- Pick 3-5 real non-functional requirements for *this* system, each with a number:
  traffic/scale, latency budget per critical path, fault tolerance (timeouts for every
  cross-boundary call; bounded retries/backoff only for idempotent operations or calls
  protected by an idempotency key — retrying a non-idempotent call can duplicate writes,
  charges, or jobs).
- Threat-model before writing code, not after. Validate inputs. Prefer vetted
  libraries over hand-rolled auth/crypto.
- Justify any optimization with a measured number — no guesswork-driven tuning.
- Wire in observability (metrics/logs/traces) and SLOs from day one, not after an
  incident forces it.
- Review by checklist, not ad hoc reading: probe empty/null inputs, boundary
  conditions, concurrent access. Security/data-loss/crash findings block merge;
  style nits don't.

(Same snippet as Claude Code's `CLAUDE.md` — Codex and Cursor both read `AGENTS.md`. Keep both
files identical except for this line if either one is edited.)
