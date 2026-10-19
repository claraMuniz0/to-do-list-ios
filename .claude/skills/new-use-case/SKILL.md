---
name: new-use-case
description: Scaffold a Domain use case (AddTodoItemUseCase, UpdateTodoItemUseCase, DeleteTodoItemUseCase style) with a hand-written TodoItemRepository test double and tests, test first. Use when adding application/business actions that orchestrate entities through the repository.
---

# New use case

Follow the `tdd-cycle` skill for commands, commits and guardrails. Test first, always.

## Location and shape
- Production: `ToDoList/Domain/UseCases/<Name>.swift`. Depends ONLY on the `TodoItemRepository` protocol and Domain types. Imports only `Foundation`.
- Test: `ToDoListTests/Domain/UseCases/<Name>Tests.swift`, Swift Testing.
- `TodoItemRepository` (Domain, `async throws`): `add`, `update`, `delete`, `task(id:)`, `allTasks()`. Do not add methods (no filters/search yet).
- Use cases are structs with constructor-injected dependencies and one `execute(...) async throws` method; no singletons, no framework types.
- Never call `Date()` in Domain. If dates matter (`complete(at:)`, "today"), inject a clock (protocol `Clock`-like, e.g. `protocol DateProvider { func now() -> Date }`) and use a fixed-date test double.

## Test double
- Hand-written, in the test target (e.g. `ToDoListTests/Doubles/TodoItemRepositorySpy.swift`). No mocking libraries.
- In-memory storage + recorded calls (`addedTasks`, `deletedIDs`, ...) + optional `errorToThrow: Error?` per method.

## Steps
- [ ] Check `TodoItemRepository` and the use case's inputs exist; if not, create via TDD first (value objects: `new-value-object`).
- [ ] RED then GREEN, one test at a time, commit each phase:
  - success: calls the right repository method with the right entity
  - edge cases: invalid input rejected BEFORE touching the repository (repository not called); unknown id -> typed domain error (e.g. `.notFound`); already-completed / duplicate cases as the rules require
  - repository failure: the repository's error propagates unchanged (`#expect(throws:)`); no partial effects, no swallowed errors, no `try?`
  - dates (if any): result uses the injected clock's fixed value
- [ ] REFACTOR while green; keep the double minimal.

## Rules
- Use cases return domain types or `Void`, never DTOs or storage models.
- View models depend on use cases, never on repositories.
- Doc comments only in the final `docs:` commit.
