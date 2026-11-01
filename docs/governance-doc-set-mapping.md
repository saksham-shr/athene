# Risk-tier → governance-doc-set mapping

Closes the "variable layer" gap the design doc names but never tabulated. The fixed baseline
(`CONTRIBUTING.md`, PR template, issue templates — see `skills/athene-audit/templates/`) is
always written, regardless of framing or risk tier. This table governs the extra docs on top of
that baseline.

## Two axes

**Project framing** — asked once, early, per the design doc: `opensource`, `startup`, `personal`,
`research`. Drives how much ownership/process ceremony makes sense — is there a group of
contributors and external reviewers who need a map, or is this one person.

**Risk tier** — not the design doc's existing per-change merge-conditions table (that scores an
individual PR's review rigor). This is a project-level tier: the *highest* category of change this
project will realistically make, using the same categories as that table as the taxonomy:

- **Low** — documentation, internal refactors, ordinary bug fixes. Never touches security, auth,
  payments, PII, or schema migrations.
- **Medium** — user-visible API/behavior changes, or database/schema migrations happen, but no
  security/credentials surface and no real external users' data at stake.
- **High** — security/auth/credentials/CI-release-policy surface exists, or the project handles
  payments/PII, or has paying/external users depending on it.

Pick the tier from what the project will realistically do, not from caution — a personal project
that touches no auth/payments/PII stays Low even if risk tiers 2 or 3 eventually log the generic
anxiety of shipping production code.

## The table

| Framing | Risk tier | Extra docs beyond fixed baseline |
|---|---|---|
| personal | Low | none |
| personal | Medium | none |
| personal | High | `SECURITY.md` |
| research | Low | none |
| research | Medium | none |
| research | High | `SECURITY.md`, release/tag policy doc |
| opensource | Low | `CODEOWNERS` (lightweight) |
| opensource | Medium | `CODEOWNERS`, commitlint in CI |
| opensource | High | `CODEOWNERS`, commitlint in CI, `SECURITY.md`, release/tag policy doc |
| startup | Low | `CODEOWNERS`, commitlint in CI |
| startup | Medium | `CODEOWNERS`, commitlint in CI, release/tag policy doc |
| startup | High | `CODEOWNERS`, commitlint in CI, `SECURITY.md`, release/tag policy doc |

## Verification against the design doc's own examples

- **Solo/fun project** (`personal` framing, `Low` risk tier — no auth/payments/PII): table says
  *none*. Matches the design doc's own stated example exactly: "a solo/fun project skips
  CODEOWNERS and SECURITY.md."
- **Opensource/startup project, high risk** (`startup` framing, `High` risk tier — handles
  payments or auth): table says `CODEOWNERS`, commitlint in CI, `SECURITY.md`, release/tag policy
  doc. Matches the design doc's own stated example exactly: "commitlint in CI, a full
  CODEOWNERS-style map, SECURITY.md, and a release/tag policy doc."

## Where this plugs in

Not yet wired into Athene: Audit's generation step — Audit's current scope (per its own SKILL.md)
is deliberately limited to the fixed baseline, with this variable layer named as a known,
deferred gap. Wiring this table into Audit (and the eventual `athene` build skill) is a follow-up,
not part of this doc.
