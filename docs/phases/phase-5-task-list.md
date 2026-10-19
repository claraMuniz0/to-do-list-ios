# Phase 5: Task List

**Status:** not started (all decisions confirmed, ready to start after Phases 3 and 4)
**Design:** `to-do.pen`: "Task List", "Task List – Swipe to Delete", "Task List – Categories", "Task List – All Done", "Task List – Delete Undo" (the Undo Toast frame)
**Depends on:** Phases 3 and 4 (list, `TodoListViewModel` with `ViewState`, SwiftData repository, Edit, `DeleteTodoItemUseCase`, `RestoreTodoItemUseCase`, Undo toast, `DateProvider`, `DueDate`, static `Category` set)

## Goal
Complete the task list experience beyond the MVP core: faster deletion, an "all caught up" state, and filtering.

## Repo state at kickoff
The repo still has only the Xcode template (`ToDoList/ContentView.swift`, `ToDoListWindow.swift`, assets). Phases 0 to 4 are fully planned but no code exists, so everything below builds on planned types. Names used here come from Phases 0 to 4; if they change during implementation, update this file.

## What the design actually contains
**Task List base** (reference, built in Phase 3)
- Subtitle "3 tasks left today" (Caveat, accent), title "My Tasks", filter pills All / Active / Done / Categories (`FilterPill` from Phase 1, All selected), sections "TO DO · 3" and "COMPLETED · 1", `Quick Add Input` pinned at the bottom.

**Swipe to Delete**
- One row ("Finish quarterly report") is shown slid left 88pt, revealing an 80x78 `danger` action with a trash icon and the label "Delete" (13pt, `on-accent`). The sliding row has a stronger shadow. Only the open rows are shown swiped; nothing shows the completed row swiped, a full-swipe, or the action's corner radius relative to the card.

**Undo Toast** ("Task List – Delete Undo")
- After the delete, subtitle "2 tasks left today", "TO DO · 2", the toast (dark pill, trash icon, "Task deleted", "Undo") sits above the Quick Add Input. Already detailed in Phase 4.

**Categories filter**
- The "Categories" pill is selected (accent fill). Below it a section header "CATEGORIES" and three radio-style rows: a color dot, the category name (16pt), a count ("2 tasks" / "1 task", 12pt), and a circular check on the right. The selected row ("Work") has an accent border and a filled check; the others have an empty circle.
- Under the three rows a soft accent "+ New category" row (accent label), then a section header "SHOWING · WORK" and the matching `TaskRow`s.
- **Inconsistency in the mock:** Work shows "2 tasks" (one open "Finish quarterly report" plus the completed "Send project update"), but "SHOWING · WORK" lists only the open one. The counts therefore include completed tasks (2 + 1 + 1 = 4 total) while the list under it shows open tasks only. We must pick one meaning (decision D3).
- Not designed: how to deselect a category (back to all), whether the "Categories" panel stays open after choosing, a category with zero tasks.

**All Done ("All caught up")**
- Subtitle becomes "All done for today" (Caveat, accent), filter pills stay (All selected), no sections. Centered: a circular illustration (a soft accent disc with a party-popper icon and colored confetti dots and dashes), title "All caught up!" (26pt), copy "You finished 4 of 4 tasks today. Enjoy the break!" (16pt secondary), and a soft pill button "View completed (4) >" (accent label, 15pt).
- The illustration is a **new asset** (a vector made of shapes plus the party-popper icon); it is not in the component library, and the Quick Add Input stays visible.
- Note the copy "4 of 4" means the count of all tasks (all completed), so "today" in the mock equals "all tasks that exist".

**Not designed (undesigned states):** Done filter with no completed tasks; Active filter with no open tasks (is it All Done?); a category with no tasks; Done filter content (assumed to be the COMPLETED section alone); a failed delete; Undo while a filter is active; swipe on completed rows; selected-filter label in the subtitle.

## Impact on earlier phases
- **Phase 3 (D1, D4):** D1's subtitle stays "N tasks left" unless C1 below changes it; D4 hid the filter pills, which Phase 5 now shows (the list view model and `TodoListView` are extended, not replaced).
- **Phase 3 (list ordering, D2):** filters reuse the same ordering function; no change.
- **Phase 4 (C3):** Delete from a swipe uses the same `undoState` on `TodoListViewModel`; no change to Phase 4 types, but the `deleted(item)` path from Edit and the swipe path should converge on one `delete(_:)` method in the list view model.
- **Phase 1:** `FilterPill` must support a selected state (it already has a selected variant in the design: All is accent-filled); a `SwipeDeleteAction`, `CategoryFilterRow` and `AllCaughtUpIllustration` are new design-system pieces (decisions F1, F2).
- **Phase 6/7 (backlog):** the "New category" row is hidden here and linked when the New Category sheet exists.

## Decisions
Recommendation in **bold**. Status `open` until you answer. Rows marked `assumed` are small and non-blocking; say if you disagree.

### A. Swipe to delete and confirmation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | Swipe mechanism | (1) custom `DragGesture` on the card row inside the existing `ScrollView`/`LazyVStack`; (2) switch the list to `List` and style `.swipeActions` to look like the design | **(1) Custom gesture.** Keeps the card layout, shadows and sections of Phase 3 untouched and matches the 88pt reveal exactly. Trade-off: we must handle gesture conflicts with vertical scroll and the circle/row taps, and accessibility ourselves (see A4). `List` swipe actions are accessible for free but fight the card styling and the 80x78 action shape | **confirmed** (recommendation accepted) |
| A2 | Delete confirmation (deferred from Phase 4 A2) | (1) none, rely on the 5 s Undo toast; (2) confirmation dialog for swipe only; (3) a dialog for both swipe and Edit | **(1) None.** Same reasoning as Phase 4: Undo is the safety net and delete is reversible; a dialog would make the fast path slow. Trade-off: an accidental full-swipe deletes right away (Undo recovers it) | **confirmed** (recommendation accepted) |
| A3 | Swipe behavior | (1) reveal then tap "Delete"; full swipe does not delete; (2) reveal plus full swipe deletes | **(1) Tap to delete only.** Matches the design (revealed button) and avoids accidental deletes. Trade-off: one extra tap | **confirmed** (recommendation accepted) |
| A4 | Accessibility alternative to swipe | (1) `accessibilityAction(named: "Delete")` on the row; (2) none (Delete from Edit is enough) | **(1) Add the custom VoiceOver action** (cheap, uses the same `delete(_:)`). Trade-off: a little extra view code | **confirmed** (recommendation accepted) |
| A5 | Swipe on completed rows | (1) yes, same behavior; (2) open rows only | **(1) Both**, consistent with Phase 4 A3 (both can open Edit). The design only shows an open row, so this is an assumption | assumed |
| A6 | Row state while the action is open | tapping elsewhere or scrolling closes it; only one row open at a time; opening another closes the first | **As described** | assumed |
| A7 | Toast and Undo after a swipe delete | reuse Phase 4 `undoState`, 5 s, new delete replaces the toast | **Reuse as is**, no changes | assumed |

### B. "Today" and the subtitle
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Subtitle meaning | (1) keep "N tasks left" counting all open tasks (Phase 3 D1); (2) "N tasks left today" counting open tasks due today or earlier plus undated | **(1) Keep Phase 3's.** A task due next week is still a task left; (2) hides work and makes the subtitle and "All caught up" disagree with the visible list. Trade-off: deviates from the design copy "left today" | **confirmed** (recommendation accepted) |
| B2 | When "All caught up" appears | (1) there is at least one task and no open task; (2) no open tasks due today or earlier | **(1) Every task is completed** (and the total is greater than zero). With zero tasks the Welcome/empty state applies instead | **confirmed** (recommendation accepted) |
| B3 | Copy "You finished N of N tasks today" | (1) "You finished N of N tasks" with N = total tasks, drop "today"; (2) count tasks completed today (`completedAt` is the same day via `DateProvider`/`Calendar`) out of tasks that were open today | **(1) Total tasks, drop "today"** ("You finished 4 of 4 tasks. Enjoy the break!"). Deterministic and always true; the mock's "4 of 4" is the total anyway. Trade-off: copy deviates slightly. (2) is richer but needs a day-scoped definition of "tasks of today" we cannot answer from the data | **confirmed** (recommendation accepted) |
| B4 | Subtitle in All Done | "All done for today" (design) | **Use "All done" without "for today"** to stay consistent with B1/B3 (assumed if B1 and B3 are accepted; otherwise keep the design copy) | assumed |
| B5 | Plural and zero | singular/plural for "N task(s) left"; "View completed (N)" with N = completed count | **As described**, tested in the view model's formatting | assumed |

### C. Filters
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Filter model | `TodoListFilter` enum in Presentation (or a Domain value if it has behavior): `all`, `active`, `done`, `category(Category)`; applied as a pure function over the already-loaded items (reuses Phase 3's ordering) | **Enum + pure filter function**, no repository change. Trade-off: filtering in memory (fine at this data size) | **confirmed** (recommendation accepted) |
| C2 | What each filter shows | All = TO DO + COMPLETED sections (as Phase 3); Active = TO DO only; Done = COMPLETED only; Category = open tasks of that category under "SHOWING · <NAME>" | **As described.** Trade-off: Category shows open only, matching the mock's list but not its count (see D3) | **confirmed** (recommendation accepted) |
| C3 | Filter persistence | (1) in memory only, resets to All each launch; (2) persist the selected filter (`UserDefaults`/`@AppStorage`) | **(1) Not persisted.** A stale "Done" or "Work" filter after relaunch looks like missing tasks; persistence also needs a new storage abstraction. Trade-off: user re-selects after relaunch | **confirmed** (recommendation accepted) |
| C4 | Where the filter state lives | `TodoListViewModel` (`selectedFilter`, `select(_:)`), part of `.loaded` state | **List view model**, tested first with fake items | assumed |
| C5 | Filter after a delete/Undo/completion | the filter stays; sections recompute; Undo restores the item and it reappears if it matches | **As described** | assumed |
| C6 | Interaction with Quick Add | adding a task while a category filter is on | **Quick Add keeps its Phase 3 defaults (Personal, due today)**; the new task may not be visible under another filter. Trade-off: could confuse; alternative is preselecting the filtered category, but that adds scope | **confirmed** (recommendation accepted) |

### D. Categories filter
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Interaction | (1) the "Categories" pill toggles a panel of three radio rows; tapping a row selects it and the list below shows that category; tapping the selected row again returns to All; (2) tapping a row closes the panel | **(1) Panel stays open while Categories is the active filter** (as the mock shows the panel with the results below); tapping the selected row deselects and falls back to All. Trade-off: deselect behavior is not in the design | **confirmed** (recommendation accepted) |
| D2 | Default selection when entering Categories | (1) the first category with tasks; (2) none selected, show only the panel and the hint; (3) first static category (Work) | **(3) Work preselected** (as in the mock, deterministic, no extra empty state). Trade-off: arbitrary | **confirmed** (recommendation accepted) |
| D3 | Count meaning in category rows | (1) open tasks only ("2 tasks" = open), matching the list under it; (2) all tasks including completed (as the mock numbers) | **(1) Open tasks only**, so the count equals what "SHOWING" lists. Trade-off: deviates from the mock's numbers (which are inconsistent with its own list) | **confirmed** (recommendation accepted) |
| D4 | "+ New category" row | (1) hidden until the New Category sheet exists (Phase 7); (2) shown but does nothing; (3) shown and opens a placeholder | **(1) Hidden**, same rule as Phase 3 D4 (no disabled placeholders). Linked later | **confirmed** (recommendation accepted) |
| D5 | Category dots and colors | color from each `Category`'s color key (work/personal/shopping chip pairs) | **Reuse the existing category color tokens** from Phase 1; no new tokens | assumed |
| D6 | Zero-count category | shown with "0 tasks", still selectable, empty state per E3 | **As described** | assumed |

### E. Empty states (mostly undesigned)
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| E1 | All caught up | design as is (illustration, copy per B3, "View completed (N)") shown when B2 holds, filter All | **As designed**, with filter pills and Quick Add still visible | **confirmed** (recommendation accepted) |
| E2 | "View completed (N)" action | (1) switches the filter to Done; (2) scrolls to a COMPLETED section; (3) opens a new screen | **(1) Switch to the Done filter.** Reuses C1/C2, no navigation. Trade-off: none | **confirmed** (recommendation accepted) |
| E3 | Empty Done filter (no completed tasks) | (1) small text empty state "Nothing completed yet" with a short hint; (2) blank | **(1) A minimal text state** (no illustration), copy to be approved by you | **confirmed** (recommendation accepted) |
| E4 | Empty Active filter | (1) reuse All caught up; (2) minimal text state "No open tasks" | **(1) Reuse All caught up** when every task is done; when there are no tasks at all the Welcome state already applies | **confirmed** (recommendation accepted) |
| E5 | Empty category (no open tasks in it) | (1) minimal text state under "SHOWING · NAME", e.g. "No open tasks in Work"; (2) hide the section header only | **(1) Minimal text state** | **confirmed** (recommendation accepted) |
| E6 | Illustration asset | (1) draw natively in SwiftUI (disc, `Image(systemName:)` party popper if available, confetti shapes); (2) export an image from the design into the asset catalog | **(1) Native SwiftUI shapes + SF Symbol** (`party.popper.fill`) so it scales and stays themeable. **Flag: option (2) edits `Assets.xcassets`/the project and needs your permission** | **confirmed** (recommendation accepted) |

### F. Presentation and structure
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| F1 | New design-system pieces | `SwipeDeleteAction` (80x78), `CategoryFilterRow` (dot, name, count, check, selected border), `AllCaughtUpIllustration`, "View completed" soft pill button; built with `new-ds-component` at the start of the phase | **As described**; `FilterPill` reused (already designed with selected state) | **confirmed** (recommendation accepted) |
| F2 | Where the swipe container lives | a reusable `SwipeToDeleteRow` wrapper (generic over content) in the design system, not inside `TaskRow` | **Wrapper**, so `TaskRow` and `TaskRowDone` stay unaware of deletion (naming-convention: `SwipeToDeleteRow`) | **confirmed** (recommendation accepted) |
| F3 | Where filter logic lives (define-location) | `TodoListFilter` + filtering function in Presentation next to `TodoListViewModel`; no new use case, no repository change | **Presentation**, because it is view-state shaping, not a business rule. If you prefer a Domain `FilterTodoItemsUseCase`, say so (more code, no new behavior) | **confirmed** (recommendation accepted) |
| F4 | View state | extend `TodoListViewModel.ViewState.loaded` with `selectedFilter`, `categoryCounts`, `isCategoriesPanelOpen`; add `.allCaughtUp` as a derived case or a flag | **Derived flag/case from the loaded data**, tested first | **confirmed** (recommendation accepted) |
| F5 | Accessibility | filter pills are buttons with selected trait; category rows are single-selection buttons announcing name, count and selected; illustration hidden from VoiceOver; Delete action named; run `accessibility-check` and check `danger` on white (13pt label) contrast | **As described** | assumed |
| F6 | Xcode project-file edits | none planned (SwiftUI/Foundation only, no new targets). Only E6 option (2) or any image asset would touch the project/assets | **No `.pbxproj` edit expected**; I will ask before any | assumed |

### G. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| G1 | Phase size and order | **One macro phase** with this order: (1) filter enum and pure filtering, tested; (2) view model state for filters, counts, All caught up; (3) filter pills and category panel UI; (4) All caught up and empty states; (5) swipe to delete. Split swipe into Phase 5b if it grows | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] `TodoListFilter` and a pure filter/count function, tested first (All, Active, Done, category)
- [ ] `TodoListViewModel`: selected filter, category open counts, All caught up state, "View completed" switching to Done, subtitle and copy formatting (singular/plural)
- [ ] `FilterPill` row wired to the view model; `CategoryFilterRow` and the Categories panel (no "New category" row)
- [ ] All caught up view and `AllCaughtUpIllustration`; minimal empty states for Done, Active and an empty category
- [ ] `SwipeToDeleteRow` and `SwipeDeleteAction`; swipe delete through `DeleteTodoItemUseCase` and the existing Undo toast; VoiceOver "Delete" action
- [ ] Previews per state (filters, categories, all caught up, swiped row); `accessibility-check`; `design-fidelity-checker`

## Out of scope
- Search and sort (Phase 6 and the backlog), the New Category sheet and the "New category" row (hidden; linked later), steps, Smart add, due date or overdue marker on the row (Phase 3 D3 stands; see below)
- Filter persistence across launches (unless C3 changes), a day-scoped "today" definition, a delete confirmation dialog (unless A2 changes)

## Open question not yet a decision row
- **Due date or overdue marker on the row:** the design never shows one, Phase 3 D3 kept the row without it, and the Active/All filters do not need it. **Recommendation: keep it off** and flag a design follow-up; confirm by answering "no change" to this note.

## Done when
- A row can be swiped left, the Delete action removes the task and the Undo toast brings it back.
- The pills All / Active / Done / Categories filter the list; the Categories panel shows counts and filters by the selected category.
- With every task completed, the "All caught up" state shows, and "View completed (N)" opens the Done filter.
- View model, filter and use case tests are green; the design-fidelity check shows no High differences.
