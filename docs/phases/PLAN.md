# To-Do List iOS — MVP Plan

Source of truth for design: `to-do.pen` (18 screens + component library). Macro phases only; each will be split into smaller TDD-sized phases later.

## Phase 0: Project foundation
- Layer structure: Domain, Presentation, Data (Clean Architecture).
- Core `TodoItem` entity and `TodoItemRepository` protocol, with an in-memory/local store behind it.
- **Done when:** the test suite runs green on an empty shell.

## Phase 1: Design system components
- **Tokens:**
  - Colors: bg, surface, border, text-primary/secondary/muted, accent, accent-soft, danger, category chip pairs (work, personal, shopping).
  - Fonts: Fraunces (heading), Bricolage Grotesque (body), Outfit (UI), Caveat (accent), DM Mono.
  - Radii: radius-md 16, radius-pill 999.
- **Components in the .pen library:** Category Chip, Task Row, Task Row Done, Primary Button, Add Task Input, Filter Pill.
- **Components seen on screens but not yet in the library:** Save Button, Category Option, Quick Add Input, Undo Toast.
- **Done when:** a preview screen renders every component, with no business logic.

## Phase 2: Welcome / Empty Tasks
- Welcome screen with the "Add First Task" button.
- First-run / empty state and navigation to Add Task.
- **Done when:** a fresh install shows this screen and the button opens an empty Add Task screen.

## Phase 3: Add Task (manual)
- **Form:** task name, optional description, category (Work / Personal / Shopping), due date (Today / Tomorrow / Next week pills + calendar sheet), Save.
- **Domain:** `TodoItemTitle` validation, `TodoItem` entity, `AddTodoItemUseCase`.
- **Minimal Task List:** open and completed tasks, tap-to-complete circle. Required so a saved task has somewhere to appear.
- **Done when:** a task can be created and shows up in the list.

## Phase 4: Edit Task
- Same form, prefilled (one form view model for Add and Edit).
- Update, and delete from the Edit screen, with Undo toast.
- **Done when:** a task can be edited (title, description, category, date) and deleted with undo.

## Phase 5: Task List (post-MVP core)
- Swipe to delete (and the delete-confirmation question), the "All caught up" state, and the filters (Active / Done / Categories).
- All decisions confirmed.

## Phase 6: Search & Sort
- Search (recent searches, category scope, results, no results with "Add as task") and a Sort menu with three options (the sort menu is undesigned, flagged for the designer).
- All decisions confirmed; built after Phase 5.

## Phase 7: Custom Categories
- "New category" sheet (name, one of 6 colors, live preview), "+ New" in the forms, the "New category" row in the Categories filter. Built-in categories keep stable ids; Phase 3 stores the category as a plain id so no migration is needed.
- All decisions confirmed; built after Phase 5.

## Post-MVP backlog (to be phased later)
- **Steps:** manual sub-steps on a task.
- **Claude features:** Smart Add (describe a task in a sentence), "Suggest steps", "Break it down".

## Phase files
- [Phase 0: Foundation](phase-0-foundation.md)
- [Phase 1: Design system](phase-1-design-system.md)
- [Phase 2: Welcome / Empty Tasks](phase-2-welcome-empty.md)
- [Phase 3: Add Task](phase-3-add-task.md)
- [Phase 4: Edit Task](phase-4-edit-task.md)
- [Phase 5: Task List](phase-5-task-list.md)
- [Phase 6: Search & Sort](phase-6-search-sort.md)
- [Phase 7: Custom Categories](phase-7-categories.md)
- [Post-MVP backlog](backlog-post-mvp.md)
