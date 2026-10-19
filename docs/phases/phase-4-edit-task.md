# Phase 4: Edit Task

**Status:** not started (all decisions confirmed, ready to start after Phase 3)
**Design:** `to-do.pen`: "Edit Task – Break it down" (the base Edit screen), "Task List – Swipe to Delete", "Undo Toast", and the list frame shown after a delete
**Depends on:** Phase 3 (form pieces, list, SwiftData repository, router), Phase 1 (`UndoToast`)

## Goal
Change or remove an existing task, with an Undo for deletes.

## What the design actually contains
**Edit Task screen (full-screen, same layout as Add Task)**
- Top nav: circular **Close (X)** button only (no Smart add).
- Header: subtitle "Make it just right", title "Edit task".
- Prefilled fields: Task name (focused, accent border), Description with a **"Break it down"** pill in its label row (post-MVP, not built), Category chips, Due date row ("Tomorrow, Oct 9"). No Steps field in this variant.
- A destructive text button **"Delete task"** (trash icon + label, `danger` color) above the Save button.
- **"Save changes"** (PrimaryButton, check icon) at the bottom.
- Design inconsistency: the mock highlights "Personal" for "Buy groceries for the week", a Shopping task. We implement from the task's real category.

**Swipe to delete (list)**
- The row slides left 88pt and reveals an 80x78 `danger` action with a trash icon and the label "Delete". The sliding row gets a stronger shadow. Swipe is listed in the post-MVP backlog.

**Undo Toast (350x48, bottom of the list)**
- Dark pill (`#2B2118`) with a white trash icon, "Task deleted" (15pt semibold) and an "Undo" action in `#FFB4A0`. Duration and animation are not designed.
- Font drift: the message uses **DM Sans**, which is not one of the five design-system fonts; "Undo" uses Outfit.

**Not designed:** delete confirmation, how long the toast stays, what happens when a second task is deleted while the toast shows, load-failure or not-found states for Edit, behavior of Edit on a completed task.

## Impact on other phases (applied to the phase 0 and 1 files; Phase 5 created)
- **Phase 0 (C6):** `TodoItem` also needs a `changeDescription(_:)` behavior, since Edit changes the description.
- **Phase 1:** the toast needs two tokens (toast background `#2B2118`, Undo color `#FFB4A0`) and the font decision in C4. A destructive text button is a new design-system piece (built at the start of this phase).
- **Phase 3 (A7):** tapping a row now opens Edit; Phase 3's view model for the form is generalized (C1).
- **Phase 5 (new):** swipe to delete, the delete-confirmation question, the "All caught up" state and the list filters move there (see `phase-5-task-list.md`).

## Decisions
Recommendation in **bold**. Status `open` until confirmed. Rows marked `assumed` are small and non-blocking; say if you disagree.

### A. Behavior
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | Swipe to delete in the MVP | (1) out, Delete from the Edit screen only; (2) in | **(1) Out.** Delete from Edit already covers the MVP, and a custom swipe on a card row needs a custom gesture or a `List`; it stays in the backlog | **confirmed** (your choice): swipe to delete is out of Phase 4 and moves to a new Phase 5, Task List |
| A2 | Delete confirmation | (1) none, rely on Undo; (2) confirmation dialog | **(1) None.** The Undo toast is the safety net | **deferred to Phase 5** (your choice): Phase 4 has no confirmation, only Undo; Phase 5 revisits it with swipe to delete |
| A3 | Which rows open Edit | (1) open and completed rows; (2) open rows only | **(1) Both.** The circle still toggles completion; tapping the rest of the row opens Edit. Editing keeps the completion state | **confirmed** (recommendation accepted) |
| A4 | Undo window | (1) 5 seconds, a new delete replaces the toast; (2) until dismissed | **(1) 5 seconds.** The first deletion becomes final when replaced or expired | **confirmed** (recommendation accepted) |
| A5 | Edit presentation | full-screen cover like Add Task | **Full-screen cover**, router-driven (assumed, consistent with Phase 3 A1) | assumed |
| A6 | Save rule | enabled whenever the draft is valid, no "unchanged" check | **As described** (assumed) | assumed |
| A7 | Close with unsaved changes | just close | **Just close** (assumed, as in Phase 3) | assumed |

### B. Domain and data
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | How Undo works | (1) delete right away; Undo re-adds the same item (same id, `createdAt`, `completedAt`); (2) delay the real delete until the toast expires | **(1) Delete right away, restore by re-adding.** With (2) a quit during the window leaves the data in an unclear state | **confirmed** (recommendation accepted) |
| B2 | Use cases | `UpdateTodoItemUseCase`, `DeleteTodoItemUseCase` (returns the deleted item), `RestoreTodoItemUseCase` | **As described.** No new repository methods: Restore uses `add` | **confirmed** (recommendation accepted) |
| B3 | Entity behavior | `changeDescription(_:)` added next to `rename`, `changeCategory`, `reschedule` | **Add it**; amends Phase 0 C6. Update applies the changes through these named methods and keeps id, `createdAt` and `completedAt` | **confirmed** (recommendation accepted) |
| B4 | Item not found when editing | repository throws `TodoItemRepositoryError.notFound`; the form view model shows a minimal error and closes | **As described**; errors are never swallowed | **confirmed** (recommendation accepted) |
| B5 | Past dates in Edit | an already-past due date is shown as is and may be kept; the picker offers today onward for new picks | **As described** (follows Phase 3 B7), covered by tests | assumed |

### C. Presentation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Add and Edit form logic | (1) one form view model with a mode (add / edit(id)); (2) a second, separate view model | **(1) One view model with a mode**, by generalizing Phase 3's, as a refactor that keeps its tests green first | **confirmed** (recommendation accepted) |
| C2 | How the Edit screen reports back | completion outcome: `saved`, `deleted(item)`, `cancelled`, delivered to the presenter (list view model) | **As described.** The list then refreshes and, for `deleted`, shows the toast | **confirmed** (recommendation accepted) |
| C3 | Who owns the toast | (1) `TodoListViewModel` holds an `undoState` with `undo()` and `dismissUndo()`; the view runs the 5-second timer; (2) a global toast center | **(1) List view model.** No real sleeps in tests | **confirmed** (recommendation accepted) |
| C4 | Toast font | (1) Outfit (`font-ui`) for the message and Undo; (2) add DM Sans | **(1) Outfit.** DM Sans is outside the design system; flag it for the design | **confirmed** (recommendation accepted) |
| C5 | "Delete task" button | a design-system component (`DestructiveTextButton`) built at the start of this phase with `new-ds-component` | **As described** | **confirmed** (recommendation accepted) |
| C6 | Accessibility | Delete has a destructive role and label; the toast is announced to VoiceOver and Undo is reachable; check the contrast of `danger` on `bg` | **As described**; run `accessibility-check` | assumed |

### D. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| D1 | Phase size and order | **One small macro phase**, after Phase 3: generalize the form view model, then Update, then Delete and Restore, then the toast | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] Refactor the Phase 3 add-form view model into a mode-based form view model (green to green)
- [ ] `TodoItem.changeDescription(_:)`, `TodoItemRepositoryError.notFound`
- [ ] `UpdateTodoItemUseCase`, `DeleteTodoItemUseCase`, `RestoreTodoItemUseCase`, each tested first; the SwiftData repository's `update`, `delete`, `task(id:)` covered with an in-memory container
- [ ] Edit mode in the form view (prefilled, "Edit task" header, "Save changes", "Delete task")
- [ ] `DestructiveTextButton` and toast tokens; `UndoToast` wired to `TodoListViewModel`
- [ ] Tapping a row opens Edit (open and completed rows); the circle still toggles completion
- [ ] Previews per state; `accessibility-check`; `design-fidelity-checker`

## Out of scope
- Swipe to delete and any delete confirmation (moved to Phase 5, Task List), "Break it down", suggested and manual steps, "+ New" category, Smart add
- A delete confirmation dialog (revisited in Phase 5), an "unsaved changes" prompt

## Done when
- A task can be edited (title, description, category, due date) and the list shows the change.
- A task can be deleted from the Edit screen, the toast shows for 5 seconds, and Undo brings back the same task in the same place.
- Use case, repository and view model tests are green; the design-fidelity check shows no High differences.
