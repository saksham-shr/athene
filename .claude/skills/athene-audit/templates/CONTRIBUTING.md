# Contributing

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`.

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`, `build`.

- `feat` — a new capability for a user.
- `fix` — a bug fix.
- `chore` — maintenance work with no user-facing effect (deps, config, tooling).
- `docs` — documentation only.
- `refactor` — code change that doesn't fix a bug or add a feature.
- `test` — adding or correcting tests.
- `perf` — a change that improves performance.
- `ci` — CI configuration and scripts.
- `build` — build system or external dependency changes.

Scope is optional but preferred: `feat(auth): add password reset flow`.

## Shortcut markers

Mark a deliberate simplification that cuts a real corner with a known ceiling
and upgrade path:

```
# athene: <ceiling>, <upgrade path>
```

Example: `# athene: global lock, per-account locks if throughput matters`.

Use it for a real shortcut with a known limit - a naive algorithm, a global
lock, a hardcoded cap - not every TODO. `scripts/debt-ledger.sh` greps the
repo for this marker and flags any instance with no named upgrade path (no
comma after the ceiling) as rot risk.

`athene:` stays distinguishable from `ponytail:`'s own marker in a repo that
uses both skills.

## No AI attribution

Commit messages and PR descriptions never carry an AI attribution or co-author trailer,
regardless of which agent wrote them. This applies equally to every contributor, human or AI.
