# Commitlint setup — write these files directly, no bundled config shipped

Earlier versions shipped `templates/commitlint.config.mjs` and
`templates/workflows/commitlint.yml` as real files inside the plugin package, copied verbatim
into the target repo. Neither ships as a bundled file any more — write their contents below
directly into the target repo yourself (a normal file write, same as any other governance
artifact this skill produces), after the existing-config detection and `configFile`
format-support checks the skill wiring this in already covers in full — don't duplicate that
list here, follow it directly before writing anything.

## `commitlint.config.mjs`

Write this exact content to the target repo's `commitlint.config.mjs`:

```js
// Enforces the Conventional Commits types from CONTRIBUTING.md in CI.
// Requires @commitlint/cli and @commitlint/config-conventional as dev dependencies.
// .mjs + export default, not .js + module.exports: wagoid/commitlint-github-action@v6
// defaults to loading commitlint.config.mjs, and a plain .js file breaks under
// "type": "module" in the target repo's package.json either way.
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'chore', 'docs', 'refactor', 'test', 'perf', 'ci', 'build'],
    ],
  },
};
```

## `.github/workflows/commitlint.yml`

Write this exact content to the target repo's `.github/workflows/commitlint.yml` — only when CI
doesn't already run commitlint some other way, same condition the skill wiring this in already
checks. Separately from that condition: **check whether a file already exists at this exact
path first.** A workflow file named `commitlint.yml` that doesn't run commitlint — a custom job
someone else named that way — is still a real, working workflow; overwriting it silently deletes
those jobs. If something's already there, don't overwrite it — tell the user what exists at that
path and either pick a different filename for this workflow or ask before replacing it.

```yaml
name: commitlint
on:
  pull_request:

permissions:
  contents: read
  pull-requests: read

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: wagoid/commitlint-github-action@v6
```

Both files need to exist together — the config alone does nothing without the CI step that runs
it, and the workflow with no `configFile` override only resolves `./commitlint.config.mjs` by
default (matching the filename above). If an alternate config format was detected instead, don't
write the workflow above unmodified — the skill wiring this in covers the `configFile` wiring
and its format-support caveats; follow that, not this file, for anything beyond the default case.
