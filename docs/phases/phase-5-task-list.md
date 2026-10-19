# Phase 5: Task List

**Status:** stub (not kicked off; run `phase-kickoff` on this file before starting)
**Design:** `to-do.pen`: "Task List", "Task List – Swipe to Delete", "Task List – Categories", "Task List – All Done", "Undo Toast"
**Depends on:** Phases 3 and 4 (minimal list, Edit, Delete, Undo toast)

## Goal
Complete the task list experience beyond the MVP core: faster deletion, an "all done" state, and filtering.

## Scope candidates (confirmed at kickoff)
- [ ] Swipe to delete: the row slides left 88pt and reveals an 80x78 `danger` Delete action (design: "Swipe Row"); reuses `DeleteTodoItemUseCase` and the Undo toast from Phase 4
- [ ] Delete confirmation: decide whether swipe or Delete-from-Edit needs one (deferred from Phase 4 A2; Undo may be enough)
- [ ] "All caught up" state: the "All done for today" header, party-popper illustration, copy "You finished N of N tasks today" and a "View completed (N)" action; needs a definition of "today" for the counts
- [ ] Filters: All / Active / Done / Categories pills; the Categories filter lists categories with task counts and a "SHOWING · WORK" section header

## Questions to settle at kickoff
- Does the header subtitle become "N tasks left today" (Phase 3 D1 chose all open tasks for the MVP)?
- Swipe mechanism: custom gesture on the card row vs a `List` with swipe actions styled to the design.
- Do filters need persistence of the selected filter?
- Do the "Categories" rows include "New category" (post-MVP category creation)?

## Out of scope (stays in the backlog)
- Search and sort, the "New category" sheet, steps, Smart add
