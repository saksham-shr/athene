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
