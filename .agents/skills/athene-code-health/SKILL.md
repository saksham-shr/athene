---
name: athene-code-health
description: >-
  Rank a repo's code quality - bugs, security holes, scale limits, missing tests, slow paths,
  bloat. One-shot report, changes nothing. Use for "audit this codebase", "review the whole
  repo". Skip for process/governance setup (use Athene: Audit) or a single-file/diff review.
---

# Athene: Code Health

Review the whole repo like the senior developer who just inherited it and will be paged when it
breaks. Order of importance: correct, safe, holds under load, tested, fast, lean. This is a
report the user asked for — give it in full, not a summary.

Distinct from Athene: Audit, which retrofits *process* (governance docs, ownership, CI) onto a
repo and never reads the code itself. This skill does the opposite: reads the code, touches no
process docs, changes nothing.

## 1. Map first

- Review what the user names — a folder, a package, or the whole repo. Nothing named: the whole
  repo.
- Read the README, build/deploy config, the dependency list, entry points (main, routes,
  handlers, jobs, CLI commands), and the tests.
- Find the expected load — one person running a script, or many users/processes at once. Judge
  scale against that, and say which load was assumed.
- Trace the main flows end to end: where data comes in, what's stored, what goes out. Read those
  paths fully — user input, money, auth, data writes, background jobs, anything shared across
  processes.
- Big repo: go deep where a mistake costs the most, not file by file. Say what wasn't read.

## 2. Look for

1. **Bug** — wrong result, crash, missed edge case (empty, zero, last item, rounding, time
   zones), callers that disagree with what a function actually returns, the same rule applied
   differently in two places.
2. **Risk** — security holes (injection, weak randomness, secrets in code, missing checks on
   user input), data loss (errors swallowed, writes in the wrong order, no transaction).
3. **Scale** — fine for one user, wrong for many: check-then-write races, the same work redone by
   every process, memory/lists that only grow, a query per item, O(n²) on big input, per-process
   state that must be shared.
4. **Missing test** — risky logic (a branch, a parser, money, security, data writes) with no
   test that fails when it breaks. One good test matters, not coverage percentage.
5. **Speed** — a real slowdown is a finding; a small win (work repeated in a hot loop) is a
   suggestion, not a must-fix, unless the project counts every millisecond.
6. **Lean** — code that shouldn't exist or should be smaller: dead code, unused options/flags,
   speculative features, two helpers doing the same thing, a dependency doing what a few lines or
   the platform already does, an interface/factory/wrapper with exactly one real implementation,
   near-copies that must change together (merge), one function doing several unrelated jobs
   (split by job, never by line count).

## 3. Quantified checks, where a tool already exists

Three dimensions above (missing test, scale/duplication under Lean) have a numeric version. Run
it only if the repo already has a tool that computes it — never add new tooling or a new
dependency to run these; that's the problem these checks exist to catch, not solve with more of
it. If no matching tool is found for a dimension, say so in `Not checked:` rather than silently
skipping it or guessing a number.

- **Complexity + coverage risk (CRAP score):** if an existing CRAP/complexity-and-coverage tool
  is already configured (CI job, existing config, a prior report on disk), run it and flag any
  function scoring `>= 10` — a Should fix, Must fix only if the function is also on a path from
  "Look for" above. CRAP combines cyclomatic complexity with how little of the function is
  covered, so it catches "complex and untested," not complexity alone.
- **Structural duplication:** if an existing structural-duplication tool is already configured
  (e.g. a CPD-style tool reporting pairwise structural similarity, not a raw text diff), run it
  and flag any pair scoring `>= 0.8` minimum pairwise similarity for merging — this is Athene's
  own proposed threshold for "worth merging," not a given tool's default; note the tool's actual
  default alongside it if different. Same finding as a near-copy under "Lean," just with a number
  behind it instead of eyeballing it.
- **Mutation testing:** if an existing mutation-testing setup is already configured for this
  stack, run it and report surviving mutants (code a test exercises but doesn't actually verify)
  and any dead code it surfaces along the way. No numeric pass threshold — report what survived
  as a Should fix per surviving mutant group, don't gate the whole report on a score.

## 4. Check before reporting

- Every finding needs a concrete case: "this input or situation leads to this wrong result." No
  case, no finding.
- Before calling code unused, grep the whole tree for it — tests, fixtures, config, string or
  dynamic references too.
- An `athene:` shortcut marker naming its own limit is a decision already made, not a finding —
  unless the expected load already crosses the limit it names.
- Propose the smallest fix that works. Prefer fixes that delete code. Never add a layer,
  framework, or config the problem doesn't need.
- No style taste, no "consider," no vague worry without a concrete case behind it.

## 5. Output

Plain English: short sentences, everyday words, explain a technical term the first time it's
used — the reader may never have seen this code.

Start with `What this repo does:` in two or three sentences, and the load assumed.

Then findings in three groups, most important first, skip empty groups:
- **Must fix** — bug, security, data loss, breaks at the expected load.
- **Should fix** — risky code with no test, real slowness, duplication, a function mixing jobs,
  code that shouldn't exist.
- **Nice to have** — small speed-ups, shorter forms.

Number findings across all groups so the user can say "fix 2 and 5." Cap at 20; if more were
found, say how many were left out. Every finding has all four parts, one or two short sentences
each:

```
2. Orders land on the wrong day (billing/close_day.py:L40-52)
   - What this is: at midnight this job closes the day and bills all orders of that day.
   - Problem: it takes "today" from the server clock (UTC). An order placed at 00:30 in Berlin
     gets billed on the day before.
   - Fix: compute the day once in the shop's time zone. One line, nothing else changes.
   - If we skip it: late orders show the wrong date, and accounting fixes them by hand.
```

End with:
- `Verdict:` one line — healthy, or what to fix first.
- `Lean: -<N> lines, -<M> dependencies possible.` when lean findings exist.
- `Not checked:` the parts not read or not run.

Nothing found: `What this repo does:`, then `Healthy. Nothing to fix.` and one line on what was
checked.

One-shot report. Changes no code.
