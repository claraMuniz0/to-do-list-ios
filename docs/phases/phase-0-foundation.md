# Phase 0: Project foundation

**Status:** not started (all decisions confirmed, ready to start)

## Goal
A green, empty shell with the Clean Architecture layers in place, so Phase 1+ can start with a failing test instead of project setup.

## Current state of the repo (checked)
- One app target (`ToDoListApp.xcodeproj`), sources in `ToDoList/`, which Xcode syncs automatically (new files need no `.pbxproj` edit).
- **No test target yet.** Adding one edits the Xcode project, which needs your explicit permission.
- `ToDoList/ToDoListWindow.swift` holds `@main struct MyApp`; `ContentView.swift` is the Xcode placeholder (imports `Playgrounds`, "Hello, world!").
- Project settings that look like defaults, not decisions: deployment target `27.0`, bundle ID `devplaceholder.…`, Swift language mode `5.0`, device family `1,2,7` (iPhone, iPad, Vision).

## Decisions to make before coding
Recommendation in **bold**. Status: `open` until you confirm.

### A. Project structure
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | Layer boundaries | (1) folders `Domain/`, `Presentation/`, `Data/` inside the app target; (2) Domain as a local Swift Package, app target depends on it | **(1) for the MVP.** Lighter, no project-file edits for source files. Revisit (2) if Domain starts importing something it shouldn't. Trade-off: (2) makes the "Domain imports no framework" rule compiler-enforced and tests run with `swift test` | **confirmed** (recommendation accepted) |
| A2 | Test target | Add an Xcode unit-test target (needs project-file edit) | **Yes, add it.** Needs your OK to touch `project.pbxproj` | **confirmed** (recommendation accepted) |
| A3 | Test framework | Swift Testing vs XCTest | **Swift Testing** (`@Test`, `#expect`), still named `*Tests.swift` per your conventions | **confirmed** (recommendation accepted) |
| A4 | Cleanup of the template | Rename `ToDoListWindow.swift`/`MyApp`, delete `ContentView` placeholder and the `Playgrounds` import | **Rename to `ToDoListApp.swift` / `ToDoListApp`**, remove the placeholder when Phase 2 adds the first real screen | **confirmed** (recommendation accepted) |

### B. Project settings (need your OK, they edit the project file)
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| B1 | Minimum iOS version (currently 27.0) | Confirm it is intended. Lower it if you want to run on a real device that is not on 27 | **confirmed**: keep 27.0 |
| B2 | Devices | **iPhone only.** The design is 390pt wide; iPad/Vision layouts are not designed | **confirmed**: iPhone only |
| B3 | Bundle identifier (currently a placeholder) | Set a real one, e.g. `com.<you>.todolist` | **confirmed**: `com.studyApp.todolist` |
| B4 | Swift language mode | **Stay on 5 for now**; moving to 6 (strict concurrency) is a separate step | **confirmed**: stay on Swift 5 |
| B5 | Simulator for `xcodebuild test` | CLAUDE.md names "iPhone 15"; check which simulators exist and pin one | **confirmed**: iPhone 17 (iOS 27.0), `-destination 'platform=iOS Simulator,name=iPhone 17'` |

### C. Domain model (the part to get right early)
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Task fields for MVP | title, description, category, due date, completion | **`TodoItemID`, `TodoItemTitle`, optional description, `Category`, optional `DueDate`, `completedAt: Date?`, `createdAt: Date`** (createdAt added in Phase 3 kickoff, B1). `completedAt` (not a Bool) supports "You finished 4 of 4 today" later | **confirmed** (recommendation accepted) |
| C2 | Category: enum or value type | enum of 3 vs value (`name` + color key) | **Value type with 3 seeded defaults.** The design has a "New category" sheet, so an enum would be thrown away in the backlog | **confirmed** (recommendation accepted) |
| C3 | Due date precision | date only vs date + time | **Date only for the MVP.** Time appears only in Smart Add (backlog). Is due date optional? Design shows "Today" prefilled | **confirmed** (recommendation accepted) |
| C4 | "Today" / "Tomorrow" / "Next week" | compute inside Domain | **Inject a `DateProvider`** (`now()`; named so because Swift already has a `Clock` protocol) so the pills are testable, never call `Date()` in Domain | **confirmed** (recommendation accepted) |
| C5 | Identity | UUID wrapped in `TodoItemID` | **`TodoItemID` value object**, generated in Domain, no database ids leaking in | **confirmed** (recommendation accepted) |
| C6 | Behavior on `TodoItem` | what it can do | **`complete(at:)`, `reopen()`, `rename(_:)`, `changeCategory(_:)`, `reschedule(_:)`**: private state, mutated only through these | **confirmed** (recommendation accepted) |
| C7 | Failure model | typed errors | **Domain error enum** (e.g. `TodoItemTitleError.empty`), thrown, never swallowed | **confirmed** (recommendation accepted) |
| C8 | Entity name | `Task` vs `TodoItem` | **`TodoItem`**: a type named `Task` shadows Swift concurrency's `Task` inside the module, breaking `Task { }` in view models. UI copy and view names still say "task" (`TaskRow`). Use cases follow `<Verb><Noun>UseCase` (e.g. `AddTodoItemUseCase`) | **confirmed** |

### D. Repository and data
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Protocol shape | sync vs `async throws` | **`async throws`**: a persistent store can replace the in-memory one without changing Domain | **confirmed** (recommendation accepted) |
| D2 | Methods needed by MVP | | `add`, `update`, `delete`, `task(id:)`, `allTasks()` (YAGNI: no filters/search yet) | **confirmed** (recommendation accepted) |
| D3 | How the list refreshes | reload after each use case vs observable stream | **Reload after each use case** for the MVP; revisit when filters arrive | **confirmed** (recommendation accepted) |
| D4 | Persistence | in-memory only vs SwiftData vs other | **In-memory for Phases 0–2, persistent store decided at the start of Phase 3.** The list is useless if tasks vanish on relaunch, so it must be settled before Phase 3 ends | **confirmed**: SwiftData, added as the first step of Phase 3 (Phase 0 stays in-memory) |
| D5 | DTO mapping | | Data layer owns a storage model, mapped to/from `TodoItem`; no framework type in Domain | **confirmed** (recommendation accepted) |

### E. Presentation
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| E1 | View-model style | **`@Observable` view models**, one per screen, depending on use cases (not repositories) | **confirmed** (recommendation accepted) |
| E2 | Navigation | **`NavigationStack` with a route enum**, owned by a small coordinator/router object | **confirmed** (recommendation accepted) |
| E3 | Dependency injection | **Manual, in a composition root** in the `@main` file. No third-party container | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] Confirm the decisions above (this file is updated with the final answers)
- [ ] Add the test target and pin the test command in the repo docs
- [ ] Rename the app entry point, set deployment target / devices / bundle ID
- [ ] Folders: `Domain/`, `Presentation/`, `Data/`; test folders mirror them
- [ ] First red→green→refactor loop on one tiny value object (`TodoItemTitle`) to prove the toolchain end to end
- [ ] `TodoItem` entity skeleton with `TodoItemID` and `Category`
- [ ] `TodoItemRepository` protocol (Domain) and `InMemoryTodoItemRepository` (Data), with tests
- [ ] Composition root wiring the in-memory repository

## Out of scope
- Persistent storage implementation (decided in D4, built in Phase 3)
- Any real screen or design-system component
- Third-party packages (need explicit permission anyway)

## Done when
- The project builds and the test suite runs green from the command line.
- `TodoItemTitle`, `TodoItem`, and `InMemoryTodoItemRepository` each have tests that were written first.
- Every row in the decision tables is `confirmed`, with the final choice written here.

## Commits
Red / green / refactor commits per the Conventional Commits rules in CLAUDE.md. Doc comments land in a separate `docs:` commit at the end of the phase.
