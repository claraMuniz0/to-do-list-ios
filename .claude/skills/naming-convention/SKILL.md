---
name: naming-convention
description: Apply this app's Swift naming conventions across Domain, Presentation and Data, and their mirrored test files. Use when creating any new type, file or test, or when a name feels inconsistent with the rest of the codebase.
---

# Naming Convention

Names say what a thing IS or DOES (Swift API Design Guidelines). Never leak layer or mechanism into the name: no `Impl`, `Protocol`, `Manager`, `Helper`.

## Domain vocabulary
The entity is `TodoItem`, never `Task` (it would shadow Swift concurrency's `Task`). UI copy and view names may still say "task" (`TaskRow`, "Add Task").

## By layer
- **Entity** (Domain): plain noun, no suffix: `TodoItem`.
- **Value objects** (Domain): the concept, not the wrapped primitive: `TodoItemID`, `TodoItemTitle`, `DueDate`, `Category`.
- **Value-object errors**: `<Type>Error`: `TodoItemTitleError`.
- **Repository protocol** (Domain): capability noun: `TodoItemRepository`.
- **Use cases** (Domain): `<Verb><Noun>UseCase` with a business verb: `AddTodoItemUseCase`, `UpdateTodoItemUseCase`, `DeleteTodoItemUseCase`. Never `Handle`/`Process`/`Do`.
- **Repository implementations** (Data): `<Source><Protocol name>`: `InMemoryTodoItemRepository`, `SwiftDataTodoItemRepository`.
- **Storage model** (Data, the SwiftData `@Model`): `<Noun>Record`: `TodoItemRecord`. Mapper: `TodoItemMapper`. Never `@Model` in Domain.
- **Views** (Presentation): `<Noun>View`. **View models**: `<Feature>ViewModel`. Pick `View`, never `Screen`.
- **Design-system components**: plain UI nouns (`PrimaryButton`, `CategoryChip`, `TaskRow`).

## Tests and fixtures
- Test file mirrors production: `Domain/TodoItemTitle.swift` -> `ToDoListTests/Domain/TodoItemTitleTests.swift`.
- Doubles in `ToDoListTests/Doubles/`: `<Type>Spy` (records calls), `<Type>Stub` (canned data); `Fake`/`Dummy` only when those don't fit.
- Factories in `ToDoListTests/Helpers/`: `make<Type>(...)` with fully defaulted parameters.
- Preview-only samples (app target, `#if DEBUG`): `.preview(...)`. The `make` prefix is reserved for the test target.

## Fast checks
- Name ends in `Protocol`/`Interface`/`Impl`: rename.
- Same concept with two names across layers (`TodoItem` vs `TodoItemModel`): collapse to one; usually a leaked storage model.
- Name has no recognizable role suffix and is not an entity/value object: probably misplaced; run `define-location`.
