# Phase 3: Add Task (manual) + minimal list

**Status:** done (all decisions confirmed and implemented, reviews applied)
**Design:** `to-do.pen`: "Add Task", "Select Date", "Task List" (plus "Components")
**Depends on:** Phase 0 (domain skeleton, test target), Phase 1 (design system), Phase 2 (router, `TodoListViewModel`, composition root)

## Goal
Create a task manually, persist it with SwiftData, and see it in a list where it can be completed and reopened.

## What the design actually contains
**Add Task screen (full-screen, 390x844)**
- Top nav: circular **Close (X)** button on the left; a **Smart add** button on the right (post-MVP, not built).
- Header: subtitle "What's on your mind?" (Caveat, accent) over the title "New task" (Fraunces italic 36).
- Fields, in order: **Task name** (focused state has an accent border; placeholder "e.g. Call the dentist"), **Description** (labelled "Optional", multi-line, placeholder "Add notes, links or any extra details..."), **Steps** (post-MVP, not built), **Category** (single choice chips: Work, Personal, Shopping, and "+ New" which is post-MVP), **Due date** (a row with calendar icon, value "Today, Oct 8" and a chevron).
- **Save task** button (PrimaryButton, check icon), full width at the bottom. In the design "Personal" is the selected category (accent stroke).
- The design has two variants of this screen: one with the Steps field and one without. The MVP uses the one **without** Steps.

**Select Date (bottom sheet over Add Task, with a scrim)**
- Grabber, title "Due date", "Clear" action, quick pills **Today / Tomorrow / Next week** (the selected one uses the accent fill), month header ("October 2026") with previous/next chevrons, weekday row S M T W T F S, a day grid whose leading/trailing days from adjacent months are muted, and a confirm button.

**Task List**
- Header: subtitle "3 tasks left today", title "My Tasks"; **Search** and **Sort** buttons (post-MVP, not built).
- Filter pills All / Active / Done / Categories (out of scope, not built).
- Section headers "TO DO · 3" and "COMPLETED · 1" with a thin rule.
- `TaskRow` (title, optional description, category chip, optional steps progress "2/5" which is post-MVP) and `TaskRowDone`. **The row does not show a due date.**
- `Quick Add Input` pinned at the bottom: placeholder "Add a new task...", an options button (sliders icon) and an accent add button.

**Not designed:** validation/error states, disabled Save button, past-date styling, what a failed save looks like, the list's loading and error states (reuse Phase 2's), how quick add behaves.

## Impact on earlier phases (applied to the phase 0, 1 and 2 files)
- **Phase 2 (B3):** the Close (X) button and the full-screen layout mean Add Task is a **modal presentation**, not a pushed screen. The router still owns it (`AppRoute`/presented state); Phase 2's placeholder should be presented the same way.
- **Phase 1:** the design system lacks a **disabled** `PrimaryButton` state, and a shared **`ScreenHeader`** (subtitle + italic title), used by Welcome, Add Task and Task List.
- **Phase 0:** if confirmed below, `TodoItem` gains `createdAt`, and the clock protocol is named `DateProvider` because `Clock` already exists in Swift.

## Decisions
Recommendation in **bold**. Status `open` until confirmed. Rows marked `assumed` are small and non-blocking; say if you disagree.

### A. Behavior
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | How Add Task is presented | (1) full-screen cover; (2) partial sheet; (3) push | **(1) Full-screen cover**, matches the full-screen design with a Close button; driven by the router | **confirmed** (recommendation accepted) |
| A2 | Default category | (1) Personal preselected (as in the design); (2) none, user must pick | **(1) Personal**. Category is required, so there is always a value | **confirmed** (recommendation accepted) |
| A3 | Default due date | (1) Today prefilled (as in the design), clearable; (2) empty | **(1) Today prefilled**; "Clear" in the date sheet removes it (due date stays optional, per C3) | **confirmed** (recommendation accepted) |
| A4 | Save and validation | (1) Save disabled until the title is valid; (2) enabled, show an inline error on tap | **(1) Disabled** since the only rule is a non-empty title and no error UI is designed | **confirmed** (recommendation accepted) |
| A5 | Quick Add defaults | Add button creates a task with title only | **Same defaults as the form** (Personal, due today). The options button opens the full form with the typed text prefilled | **confirmed** (recommendation accepted) |
| A6 | Close with unsaved input | confirm discard vs just close | **Just close** (assumed; no confirmation designed) | assumed |
| A7 | Tapping a row | open Edit vs nothing | **Nothing in this phase** (assumed); only the circle toggles completion. Edit arrives in Phase 4 | assumed |
| A8 | Completing a task | instant vs undo | **Instant toggle** (assumed); it moves between TO DO and COMPLETED | assumed |

### B. Domain
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Creation timestamp | add `createdAt` to `TodoItem` or not | **Add `createdAt`** (set through `DateProvider`) so ordering is deterministic; amends Phase 0 C1 | **confirmed** (recommendation accepted) |
| B2 | `DueDate` representation | (1) year-month-day value; (2) `Date` at start of day | **(1) Year-month-day** (`Calendar` injected), so a time-zone change never shifts the day | **confirmed** (recommendation accepted) |
| B3 | Clock naming | `Clock` vs `DateProvider` | **`DateProvider`** (`now()`), because Swift already has a `Clock` protocol | **confirmed** (recommendation accepted) |
| B4 | Title rules | non-empty after trimming; maximum length? | **Trimmed, non-empty, max 120 characters**; the field limits input so no error message is needed | **confirmed** (recommendation accepted) |
| B5 | Description rules | optional | **Trimmed; empty becomes nil; no maximum** (assumed) | assumed |
| B6 | "Next week" | (1) today + 7 days; (2) next Monday | **(1) Today + 7 days**, unambiguous | **confirmed** (recommendation accepted) |
| B7 | Past dates | (1) domain allows any day, picker only offers today onward for new dates; (2) domain rejects the past | **(1)**: a saved task's date becomes past naturally, and Edit must still show it | **confirmed** (recommendation accepted) |
| B8 | Categories | (1) `CategoryID` + name + color, seeded built-ins with stable ids `work`, `personal`, `shopping`; (2) a `CategoryRepository` | **(1) Seeded static set in Domain, shaped for Phase 7**: `Category` = `CategoryID` (string value object) + `CategoryName` + `CategoryColor`. "+ New" and custom categories are post-MVP (Phase 7). Amended from the earlier "name + color key" after the Phase 7 kickoff | **confirmed** (recommendation accepted) |
| B9 | Date label format | | **"Today, Oct 8" / "Tomorrow, Oct 9" / "Tue, Oct 13"** produced in Presentation from `DateProvider` and `Calendar` (assumed) | assumed |

### C. Data (SwiftData)
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Storage record | `@Model TodoItemRecord` in Data, mapped by `TodoItemMapper`; due date stored as year/month/day integers, category as a plain `categoryID: String` (no enum, relationship, or copied name/color) | **As described**; never `@Model` in Domain (decision D5). `TodoItemMapper` takes a category lookup and falls back to Personal if the id is unknown (covered by a test). Phase 7 then only adds a `CategoryRecord` | **confirmed** (recommendation accepted) |
| C2 | Concurrency of the repository | (1) `@MainActor` repository on the main `ModelContext`; (2) `@ModelActor` background context | **(1) `@MainActor`** for the MVP (small data, simpler). Revisit if data grows | **confirmed** (recommendation accepted) |
| C3 | Container and tests | one `ModelContainer` built in the composition root; tests and previews use an in-memory container | **As described**. SwiftData is a system framework: no project-file edit and no package | **confirmed** (recommendation accepted) |
| C4 | Schema versioning | none for the MVP | **None** (assumed). Any later model change needs a migration decision | assumed |

### D. Task list
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Header subtitle | (1) "N tasks left" counting all open tasks; (2) "left today": open tasks due today or earlier | **(1) All open tasks**, with singular/plural; the "today" meaning comes with the post-MVP filters. Deviates from the design copy | **confirmed** (recommendation accepted) |
| D2 | Ordering | open: due date ascending (no date last), then oldest created first; completed: most recently completed first | **As described.** Note the row does not show the date, so the order can look arbitrary | **confirmed** (recommendation accepted) |
| D3 | Show the due date on the row | (1) keep the design (not shown); (2) add a small date to the row | **(1) Keep the design**, flag it for a design follow-up | **confirmed** (recommendation accepted) |
| D4 | Hidden in the MVP | Search, Sort, filter pills, steps progress, Smart add, "+ New" | **Not built**, not shown (no disabled placeholders) | **confirmed** (recommendation accepted) |

### E. UI building blocks
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| E1 | Date picker | (1) system graphical `DatePicker` in the sheet, styled with the accent tint; (2) custom month grid matching the design | **(1) System `DatePicker` for the MVP**, with the Today/Tomorrow/Next week pills and Clear above it. Custom grid is post-MVP polish | **confirmed** (recommendation accepted) |
| E2 | Where the new form components live | text input, text area, form field (label + optional tag), date row, circular icon button, section header | **Design system folder, built with `new-ds-component` at the start of this phase** (not in Phase 1) | **confirmed** (recommendation accepted) |
| E3 | Disabled `PrimaryButton` | undesigned | **Reduced opacity (0.4) and no shadow**; token noted for the design | **confirmed** (recommendation accepted) |
| E4 | Shared `ScreenHeader` (subtitle + italic title) | add to Phase 1 vs build here | **Add to Phase 1 and use it in Phases 2 and 3** | **confirmed** (recommendation accepted) |
| E5 | Phase size | one macro phase vs split now | **Keep one macro phase** with this internal order: persistence, domain, Add Task form, list and quick add. Split further later | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
### Persistence (first step)
- [x] `TodoItemRecord` (`@Model`) in Data, `TodoItemMapper`, with tests
- [x] `SwiftDataTodoItemRepository` implementing `TodoItemRepository`, tested with an in-memory `ModelContainer`
- [x] Composition root swaps `InMemoryTodoItemRepository` for SwiftData (in-memory kept for tests and previews)

### Domain
- [x] `DateProvider`; `DueDate`; `CategoryID`, `CategoryName`, `CategoryColor` and `Category` (seeded Work/Personal/Shopping, stable ids); `TodoItemTitle` (trim, non-empty, max length); `TodoItem.createdAt`
- [x] `AddTodoItemUseCase`; `CompleteTodoItemUseCase` and `ReopenTodoItemUseCase` (or one toggle use case); ordering of open and completed lists (a pure function with tests)
- [x] Quick-add path through `AddTodoItemUseCase` with the defaults from A5

### Add Task form
- [x] `AddTodoItemViewModel` (tested first): title, description, category, due date, validity, save, failure
- [x] New design-system pieces from E2, `ScreenHeader` and disabled `PrimaryButton`
- [x] `AddTodoItemView` (full-screen cover) and the Select Date sheet with the pills, Clear, picker and confirm

### Task list
- [x] `TodoListViewModel` `.loaded` state: TO DO and COMPLETED sections, counts, toggle completion, refresh after every use case
- [x] `TodoListView`, `TaskRow`/`TaskRowDone` integration, `QuickAddInput`
- [x] Previews per state; `accessibility-check`; `design-fidelity-checker`

## Out of scope
- Edit and delete (Phase 4), filters, search, sort, swipe to delete, "All caught up"
- Steps, "+ New" category, Smart add, due date on the row, custom calendar grid

## Done when
- A task can be created from the form or quick add, survives an app relaunch, and appears in the list.
- The circle completes and reopens it, moving it between TO DO and COMPLETED.
- Domain, view model and repository tests are green; the design-fidelity check shows no High differences.

## Build notes
- Test-first throughout Domain, Data and the two view models (red `test:` commit, then green `feat:`). Exceptions: the router prefill change (`AppRoute.addTodoItem(prefill:)`) and the SwiftUI views (`AddTodoItemView`, `SelectDateSheet`, `TodoListView`) were not preceded by a red commit; views have previews, not unit tests.
- Persistence: `TodoItemRecord` (`@Model`) + `TodoItemMapper` + `SwiftDataTodoItemRepository` (`@MainActor`, main context, holds its `ModelContainer`, which a `ModelContext` does not retain). `allTasks()` is sorted oldest created first. `AppDependencies.live()` is disk-backed and `inMemory()` serves tests and previews.
- Domain: `Category` is now `CategoryID` + `CategoryName` + `CategoryColor`; `TodoItemTitle.maxLength` is 120 (`.tooLong`); `AddTodoItemUseCase` (with `quickAdd`), `ToggleTodoItemCompletionUseCase` (one toggle use case instead of complete + reopen), `TodoListSections` (ordering as a pure type).
- Presentation: `AddTodoItemViewModel`, `DueDateLabel` ("Today, Oct 8" with a fixed order, the locale only supplies names), `DueDatePickerAdapter`, `TodoListViewModel` `.loaded(TodoListSections)` with `toggle` and `quickAdd`.
- The test target needs the iOS 27 simulator (iPhone 18 Pro); `DSColorTests` has an intermittent crash under parallel runs (UIColor race), unrelated to this phase.
- Bug found by running the app: a toggled row kept its old look because `LazyVStack` reused it across sections; fixed with a state-dependent `.id`.
- Reviews applied: save failure is announced, "Clear" has a 44pt hit area, design gradient on list and form, partial date sheet with surface fill and 28pt corners, button copy "Set date".

## Follow-ups (not done in this phase)
- `DueDate` is not self-validating (month 13 is accepted) and has silent `??` fallbacks (Phase 0 code); consider a throwing init and a corrupt-record error in the mapper.
- Design: Close button has a soft shadow the design does not; calendar icon is an SF grid symbol, design uses an outline `calendar`; Task name input is about 50pt vs 57pt in the design, text area 111 vs 104; custom calendar grid and header (E1, post-MVP); sheet scrim is the system dim, not the designed 50% `#2B2118`.
- Accessibility (Medium): `TaskRow` reads the title twice and could be one element with a named action; form labels are not tied to inputs; category chips repeat label and selected trait; quick-add bar is cramped at accessibility sizes; fixed-size icons do not scale; disabled Save has no hint; keyboard hides Category and Due date (scrolls only).
- Tests (Medium): more cases for `SwiftDataTodoItemRepository` (corrupt record, `createdAt` kept on update), `TodoItemMapper` (partial due date, empty details), `AddTodoItemViewModel` (double submit, year rollover), `DueDateLabel` (other year or locale), a spy with separate per-method errors, and `TodoListViewModel` wiring for the quick-add options route.
- Architecture (Medium/Low): unknown `categoryID` falls back to Personal silently (decision C1, keep or throw); `Category` seeds use `try!`; the "non-blank title" rule is repeated in two view models (expose it from `TodoItemTitle`); previews build a Data repository inside Presentation files.
