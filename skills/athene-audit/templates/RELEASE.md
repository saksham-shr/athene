# Release and tag policy

## Versioning

[Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`. Pre-release suffix when needed:
`-beta.N`, `-rc.N`. Never ad hoc names (`release-1`, `final-version`).

## Tags vs. releases vs. packages

- **Tag** — a fixed marker on one commit. Push it first.
- **Release** — sits on top of a tag: release notes, doc links, downloadable assets. The
  user-facing layer.
- **Package** (if this repo publishes one) — the built artifact (library, container image),
  published by CI on tag push. Don't assume a tag and a package version stay in sync unless a
  workflow enforces it.

## Process

1. Tag the commit: `git tag -a vX.Y.Z -m "..."` then `git push origin vX.Y.Z` — push that one
   tag explicitly, not `git push --tags`, which pushes every unpushed local tag and can trigger
   an unintended release if another one matches a release workflow.
2. A workflow triggered on `v*` tags creates the GitHub release and publishes any package —
   one tag push, not three manual steps. (Wire this up in CI once the repo actually ships a
   package; a tag-only release is fine until then.)
3. Rollback: revert the tag's commit on the default branch, cut a new patch release. Don't move
   or delete a published tag — if a release was wrong, ship a new one.
