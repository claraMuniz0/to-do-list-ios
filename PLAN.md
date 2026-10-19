# To-Do List iOS — MVP Plan

Source of truth for design: `to-do.pen` (18 screens + component library). Macro phases only; each will be split into smaller TDD-sized phases later.

## Phase 0: Project foundation
- Layer structure: Domain, Presentation, Data (Clean Architecture).
- Core `Task` entity and `TaskRepository` protocol, with an in-memory/local store behind it.
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
- **Domain:** `TaskTitle` validation, `Task` entity, `AddTask` use case.
- **Minimal Task List:** open and completed tasks, tap-to-complete circle. Required so a saved task has somewhere to appear.
- **Done when:** a task can be created and shows up in the list.

## Phase 4: Edit Task
- Same form, prefilled.
- Update and delete, with Undo toast.
- **Done when:** a task can be edited (title, description, category, date) and deleted with undo.

## Post-MVP backlog (to be phased later)
- **Task List extras:** Active / Done / Categories filters, swipe to delete, search (recent, by category, no-results state), "All caught up" state.
- **Create-category sheet:** new category with color and preview.
- **Steps:** manual sub-steps on a task.
- **Claude features:** Smart Add (describe a task in a sentence), "Suggest steps", "Break it down".
