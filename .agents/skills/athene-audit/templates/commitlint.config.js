// Enforces the Conventional Commits types from CONTRIBUTING.md in CI.
// Requires @commitlint/cli and @commitlint/config-conventional as dev dependencies.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'chore', 'docs', 'refactor', 'test', 'perf', 'ci', 'build'],
    ],
  },
};
