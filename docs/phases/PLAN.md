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

## Phase 2: Welcome / Empty Tasks (done)
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
- Done.

## Phase 6: Search & Sort
- Search (recent searches, category scope, results, no results with "Add as task") and a Sort menu with three options (the sort menu is undesigned, flagged for the designer).
- Done.

## Phase 7: Custom Categories
- "New category" sheet (name, one of 6 colors, live preview), "+ New" in the forms, the "New category" row in the Categories filter. Built-in categories keep stable ids; Phase 3 stores the category as a plain id so no migration is needed.
- All decisions confirmed; built after Phase 5.

## Claude foundation (prerequisite for Phases 8 and 9)
- `ClaudeClient` over `URLSession` (Messages API, forced tool call), `ClaudeError`, API key read from a git-ignored config file, test doubles. No UI.
- All decisions confirmed; built first, by one agent.

## Phase 8: Steps (manual + Claude)
- Steps on a task (add, tick, rename, delete, reorder, progress, "2/5" on the row), "Break it down", "Suggest more" and the Suggested steps sheet.
- All decisions confirmed; built in parallel with Phase 9 after the foundation.

## Phase 9: Smart Add
- Describe screen (sentence, counter, examples) and Review screen (the Add form prefilled by Claude, banner, Save). Date only, no priority, no mic.
- All decisions confirmed; built in parallel with Phase 8 after the foundation.

## Phase 10: Splash Screen
- Branded launch screen handing off to Welcome / the list once loading finishes, no artificial delay, Reduce Motion honored.
- All decisions confirmed; independent of Phases 5 to 9.

## Post-MVP backlog (to be phased later)
- See [backlog](backlog-post-mvp.md).

## Phase files
- [Phase 0: Foundation](phase-0-foundation.md)
- [Phase 1: Design system](phase-1-design-system.md)
- [Phase 2: Welcome / Empty Tasks](phase-2-welcome-empty.md)
- [Phase 3: Add Task](phase-3-add-task.md)
- [Phase 4: Edit Task](phase-4-edit-task.md)
- [Phase 5: Task List](phase-5-task-list.md)
- [Phase 6: Search & Sort](phase-6-search-sort.md)
- [Phase 7: Custom Categories](phase-7-categories.md)
- [Claude foundation](claude-foundation.md)
- [Phase 8: Steps](phase-8-steps.md)
- [Phase 9: Smart Add](phase-9-smart-add.md)
- [Phase 10: Splash Screen](phase-10-splash.md)
- [Post-MVP backlog](backlog-post-mvp.md)
