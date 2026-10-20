---
name: doc-comments-pass
description: Add `///` doc comments to a finished feature's public Swift types and functions. Trigger ONLY after a feature's tests are green and its feat/refactor commits are done (typically the end of a phase), or when the user asks for the doc-comment pass. Never during red/green/refactor.
---

# Doc comments pass

Runs as its own pass and its own `docs:` commit, never mixed into a `feat:` or `refactor:` commit.

## Preconditions
1. Run the test suite (`swift test` or the `xcodebuild test` command pinned in the repo docs). If it is not green, stop: fix that first, this pass does not start on red.
2. Working tree should be clean apart from this pass. If feature changes are uncommitted, ask the user to commit them first.

## Procedure
1. List the public/internal API the feature added (types, functions, properties, initializers). Use grep to locate them; do not read whole files you don't need.
2. For each member, decide: do the name and signature already say what it does?
   - **Yes: skip it.** Trivial or self-evident members get no comment (simple getters, obvious initializers, `id`, `title`).
   - **No: add a `///` comment.**
3. Document the WHY only, never restate the WHAT. Worth documenting:
   - Edge cases (empty, boundary values, time zones, past dates).
   - Non-obvious invariants (e.g. state only mutable through named methods).
   - Failure conditions on validated value objects (what makes `TodoItemTitle(...)` throw, and which error).
   - Naming collisions (the entity is `TodoItem`, not `Task`, so it does not shadow Swift concurrency's `Task`; keep it that way).
   - Why a design choice exists when a reader would otherwise "fix" it (e.g. `completedAt: Date?` instead of a Bool).
4. Style: one short summary line, then extra lines only if needed. Use `- Throws:` for failure conditions. No `@param`-style noise that repeats parameter names.
5. Change comments only. Do not touch code, formatting, or tests.

## Finish
1. Re-run the tests and confirm they are still green.
2. Check the diff contains only comment lines (`git diff` should show `///` additions).
3. Commit: `docs: add doc comments to [feature]`. No other changes in it.
