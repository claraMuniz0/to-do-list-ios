# Phase 6: Search & Sort

**Status:** done (all decisions confirmed and implemented, reviews applied; open follow-ups below)
**Design:** `to-do.pen`: "Search – Recent", "Search" (the results frame, query "gro"), "Search – No Results", plus the Search and Sort buttons in the "Task List" header. **There is no frame for the Sort menu.**
**Depends on:** Phase 3 (list, `TodoListViewModel`, router, `AddTodoItemUseCase`, ordering function, form with a prefilled title), Phase 4 (Edit, Delete, Undo toast), Phase 1 (design system). Built after Phase 5 so the list header is final (no code dependency on its filters, see H1).

## Goal
Find a task by typing, jump back to earlier searches, turn an unfound query into a new task, and choose how the list is ordered.

## What the design actually contains
**Entry points (Task List header, "Header Actions")**
- Two 44x44 circular `surface` buttons: **Search** (`search` icon, 20pt) and **Sort** (`arrow-up-down` icon, 20pt). Phase 3 D4 kept both out of the MVP; this phase adds them. They are the circular icon button from Phase 3 E2.

**Search – Recent (empty query)**
- Replaces the whole screen (status bar, content, keyboard). Top row: a 48pt-high `surface` field (accent `search` icon, caret, placeholder "Search tasks...", a `circle-x` clear icon in `text-muted`) and a text button **"Cancel"** in `accent`.
- **RECENT** label (`text-muted`) with a **"Clear all"** link (`accent`); rows (52pt): `clock-3` icon, the term, and an `arrow-up-left` icon (the "fill the field" affordance). Three sample rows: groceries, dentist, report.
- **BY CATEGORY** section header with a rule, then three large chips (Work, Personal, Shopping). These are bigger than the row chip (padding 10x16, 14pt text), so `CategoryChip` needs a size variant. No selected state is designed.
- The keyboard is open (the design draws a custom keyboard; the app uses the system one, with a "search" return key).

**Search – Results (query "gro")**
- Same field row with the typed text. Header **"2 RESULTS"** with a rule, then `TaskRow` instances (title, optional description, category chip; the first still shows the steps progress "2/5", which is post-MVP and not built). Both results are open tasks, so the design does not show completed tasks in results, sections, or highlighted matches. The second result ("Plan grocery budget") has no description, so it matches on the title; "Buy groceries for the week" matches on the title as well. Nothing in the design proves description matching.

**Search – No Results (query "gym")**
- Centered illustration (140pt halo in `accent-soft`, 90pt `surface` disc, `search-x` icon, two small dots; buildable from shapes, no asset), title **"No tasks found"**, description "Try a different word, or add it as a new task.", and a `PrimaryButton` with a `plus` icon labelled **Add “gym” as a task** (curly quotes).

**Sort**
- The button exists; **no menu, sheet or indicator is designed**. Proposed in G1 to G3 and flagged for the designer.

**Not designed:** how a category chip behaves, a selected chip, result highlighting, completed tasks in results, singular "1 RESULT", long queries in the "Add ... as a task" label, what happens after "Add as task" saves, Clear all confirmation, an active-sort indicator, keyboard dismissal, loading or error state of search, the Sort menu (all of it).

## Impact on earlier phases
- **Phase 3 (D4, D2):** the hidden Search and Sort buttons are now built. The ordering function (D2) must take a sort order; the default stays "due date ascending, then oldest created". The form's "prefilled title" input (already used by Quick Add's options button, A5) is reused by "Add as task".
- **Phase 0 (D2, D3):** the repository stays at `add`, `update`, `delete`, `task(id:)`, `allTasks()`: search does not add a repository method (B1). Reload-after-each-use-case also applies to the search view model.
- **Phase 4 (A3, C2, C3):** a result row opens Edit and the outcome (`saved`, `deleted(item)`, `cancelled`) is delivered to the search view model, but the Undo toast belongs to `TodoListViewModel` (F2).
- **Phase 5:** list filters and search stay independent (H1). Phase 5's header (Search and Sort buttons next to the title) is assumed; flag if Phase 5's kickoff changes it. **No PLAN.md edit is made here:** PLAN.md needs a Phase 6 entry and a file link, and the backlog line "Task List extras: search and sort" is consumed by this phase; please confirm those two edits.
- **Phase 1:** new design-system pieces (F5): `SearchField`, `RecentSearchRow`, a `CategoryChip` size variant and an empty-state illustration block (the same halo and disc pattern is likely reused by Phase 5's "All caught up").

## Decisions
Recommendation in **bold**. Status `open` until confirmed. Rows marked `assumed` are small and non-blocking; say if you disagree.

### A. Matching rules
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | Fields searched | (1) title only; (2) title and description | **(2) Title and description.** The design shows descriptions on results and users write details there. Trade-off: slightly noisier results. Category name is not searched (the chips cover it) | **confirmed** (recommendation accepted) |
| A2 | Normalization | (1) exact; (2) case- and diacritic-insensitive | **(2) Case and diacritic insensitive** ("cafe" finds "Café"), via Foundation folding (no framework needed in Domain). Trade-off: a little more code than `contains`, covered by tests | **confirmed** (recommendation accepted) |
| A3 | Match style | (1) substring; (2) word prefix; (3) fuzzy | **(1) Substring** of the trimmed query: "gro" finds "Plan grocery budget" and also "Agro". Trade-off: more matches than word-prefix, but predictable and trivial to test. No fuzzy matching (YAGNI) | **confirmed** (recommendation accepted) |
| A4 | Completed tasks in results | (1) include; (2) open only | **(1) Include**, shown with `TaskRowDone`, listed after open ones. Users search to find something they did; hiding it looks like data loss. Trade-off: the design shows only open rows | **confirmed** (recommendation accepted) |
| A5 | Query rules | max length, whitespace | **Trimmed; an empty or whitespace-only query shows the Recent state; max 120 characters (same as the title) so "Add as task" always fits `TodoItemTitle`**. Multiple words are one substring (no AND-terms) | **confirmed** (recommendation accepted) |
| A6 | Results order and layout | (1) flat list, open then completed, in the list's current sort order; (2) sections like the list | **(1) Flat list** under "N RESULTS" (design), open first, each part ordered by the sort order from G1. Singular "1 RESULT" (assumed) | **confirmed** (recommendation accepted) |
| A7 | Match highlighting | none vs bold the match | **None** (assumed; not designed) | assumed |

### B. Where the logic lives
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Where filtering happens | (1) Domain use case over `allTasks()`; (2) view model; (3) new repository query (SwiftData `#Predicate`) | **(1) Domain use case**: `SearchTodoItemsUseCase` loads `allTasks()` and applies a pure matcher. Business rule stays testable without UI or SwiftData; diacritic-insensitive predicates are limited in SwiftData and would leak storage into the rule. Trade-off: loads every task per search, fine for a personal to-do list (revisit if data grows, as Phase 3 C2 says) | **confirmed** (recommendation accepted) |
| B2 | Live results and debounce | (1) filter on every keystroke, no debounce; (2) debounce 250ms | **(1) No debounce.** The work is an in-memory filter; the view model loads tasks once when search opens and refreshes after each mutation. No timers means no real sleeps in tests. Trade-off: if data ever becomes large, add a debounce then | **confirmed** (recommendation accepted) |
| B3 | Domain types | | **`SearchQuery` value object** (trim, non-empty, max 120, self-validating), `TodoItemSearchMatcher`-style pure function inside the use case, `SearchTodoItemsUseCase` (query + optional `Category` scope), and `RecentSearch` handling by the use cases in C1. Names follow `naming-convention` (`<Verb><Noun>UseCase`, entity is `TodoItem`) | **confirmed** (recommendation accepted) |
| B4 | Layer placement (`define-location`) | | **Domain:** `SearchQuery`, `SearchTodoItemsUseCase`, `RecentSearchRepository` protocol, recent-search use cases, `TodoItemSortOrder`, `SortOrderRepository` protocol. **Presentation:** `TodoSearchViewModel`, `TodoSearchView`, search components, sort menu. **Data:** `UserDefaultsRecentSearchRepository`, `UserDefaultsSortOrderRepository`. Composition root wires them | **confirmed** (recommendation accepted) |

### C. Recent searches
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Storage | (1) UserDefaults behind a Domain repository protocol; (2) SwiftData `@Model` | **(1) UserDefaults** (`RecentSearchRepository`, impl `UserDefaultsRecentSearchRepository`, tests use an isolated suite). A short list of strings is not relational data, and a new `@Model` would force the schema-versioning question left open in Phase 3 C4. Trade-off: a second storage mechanism. UserDefaults is a system framework: no project-file edit | **confirmed** (recommendation accepted) |
| C2 | Limit and duplicates | | **Keep the 8 most recent, show all 8** (design shows 3); the same term (case and diacritic insensitive) moves to the top instead of duplicating | **confirmed** (recommendation accepted) |
| C3 | When a search is recorded | (1) on keyboard "search" key or tapping a result, only if it had at least one result; (2) on every keystroke; (3) any submit | **(1)** so the list holds useful shortcuts, not "gy" or "gym" with nothing found. Trade-off: a no-result query is not remembered | **confirmed** (recommendation accepted) |
| C4 | Tapping a recent row vs the arrow | | **Row tap fills the field and runs the search** (counts as submitted, so it moves to the top); **the `arrow-up-left` fills the field only**, to keep editing the term. Trade-off: two targets per row, both 44pt tall | **confirmed** (recommendation accepted) |
| C5 | Clear all | (1) immediate; (2) confirmation | **(1) Immediate**, no confirmation (assumed; low-stakes, and nothing is designed). No per-row delete (not designed) | assumed |

### D. Category chips
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | What a chip does | (1) a category scope inside search: show that category's tasks; (2) close search and apply Phase 5's category filter on the list; (3) put the category name in the query | **(1) Scope inside search.** Tapping a chip shows its tasks as "N RESULTS" with the chip drawn selected (accent stroke, like the form); tapping it again clears the scope. Not saved to Recent. Trade-off: a scope state (`Category?`) the design does not draw; flag the selected style for the designer | **confirmed** (recommendation accepted) |
| D2 | Chip together with a query | | **Scope and query combine (AND).** Chips are designed only in the Recent state, so **show them only there**; once a scope is chosen, show it as one selected chip above "N RESULTS" so it can be removed (assumed) | **confirmed** (recommendation accepted) |
| D3 | Chip colors and size | | **Reuse `CategoryChip` with a larger size variant** (padding 10x16, 14pt), colors from the existing chip tokens | assumed |

### E. "Add as task"
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| E1 | What it does | | **Opens the full Add form (Phase 3) as a cover, with the title prefilled from the trimmed query**, same defaults (Personal, due today), or the scoped category if a chip is selected. It does not save directly: the user confirms the details. Reuses the same "prefilled title" entry as Quick Add's options button. Label is `Add “<query>” as a task`, one line, truncated in the middle | **confirmed** (recommendation accepted) |
| E2 | After saving from the form | (1) stay in search and re-run the query, so the new task appears; (2) close search and return to the list | **(1) Stay and re-run.** Confirms the add in place; the "Add as task" button disappears because there is now a result. Trade-off: two stacked full-screen covers (Search, then Add), so the router must support a cover presented over a cover | **confirmed** (recommendation accepted) |
| E3 | When the button shows | | **Only in the no-results state with a non-empty query** (as designed); not in the Recent state, and not when a category scope without a query yields nothing (assumed) | assumed |

### F. Presentation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| F1 | Search presentation | (1) full-screen cover via the router; (2) inline replacing the list header (`.searchable`); (3) push | **(1) Full-screen cover**, matching the design (own status/search bar, Cancel, keyboard) and Add/Edit (Phase 3 A1, Phase 4 A5). `.searchable` cannot reproduce the 48pt field and the Recent layout. Trade-off: custom field, but full design fidelity | **confirmed** (recommendation accepted) |
| F2 | Interactions on a result | | **Circle toggles completion and the results refresh; tapping the rest of the row opens Edit** (Phase 4 A3), as a cover over search. On `deleted(item)` the search closes and forwards the item to `TodoListViewModel`, so the existing 5-second Undo toast shows on the list. On `saved` it re-runs the query. Trade-off: delete from search jumps back to the list | **confirmed** (recommendation accepted) |
| F3 | Keyboard | | **Focus the field when search opens (`@FocusState`); "search" return key (`.submitLabel(.search)`) records the query and dismisses the keyboard; scrolling results dismisses it (`.scrollDismissesKeyboard(.interactively)`); the clear icon empties the field and keeps focus; Cancel closes search.** The design's drawn keyboard is the system keyboard, not built. The layout must follow the keyboard safe area so the no-results button stays visible | **confirmed** (recommendation accepted) |
| F4 | Accessibility | | **As described, run `accessibility-check`:** field labelled "Search tasks"; clear icon 44pt hit target labelled "Clear text"; Cancel 44pt; decorative icons hidden; "N results" and "No tasks found" announced to VoiceOver when they change (`AccessibilityNotification.Announcement`, only on submit or count change, not per keystroke); recent rows read "Recent search, groceries" with the arrow as a separate "Use groceries" action; Dynamic Type for the field, rows and chips; chip selected state exposed as a trait, not only color | **confirmed** (recommendation accepted) |
| F5 | New components (Presentation, design system) | | **Built with `new-ds-component`:** `SearchField`, `RecentSearchRow`, `CategoryChip` large size, `EmptyStateIllustration` (halo, disc, dots, icon), reusing the circular icon button, section header, `TaskRow`, `TaskRowDone` and `PrimaryButton` | **confirmed** (recommendation accepted) |
| F6 | State of the view model | | **`TodoSearchViewModel` (`@Observable`)** with states `recent`, `results([TodoItem])`, `noResults(query)`, plus `query`, `scope`, and `recentSearches`; depends on use cases only (Phase 0 E1). Search state is not persisted: reopening search starts empty (assumed) | **confirmed** (recommendation accepted) |

### G. Sort (undesigned: needs the designer)
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| G1 | Options | | **Three: "Due date" (default, today's order from Phase 3 D2), "Newest first" (`createdAt` descending), "Title A to Z" (case and diacritic insensitive).** Minimal on purpose: those three use fields the entity already has. Category sort and manual drag order are left out (YAGNI). Modeled as `TodoItemSortOrder` in Domain | **confirmed** (recommendation accepted) |
| G2 | UI | (1) system `Menu` on the Sort button with a checkmark on the active item; (2) bottom sheet like the date sheet | **(1) System `Menu`**, no new component, no design needed to start. Flag for the designer: menu or sheet, icon states, and an active-sort indicator (none built, assumed) | **confirmed** (recommendation accepted) |
| G3 | Persistence | (1) remember the choice (UserDefaults behind `SortOrderRepository`); (2) reset to Due date each launch | **(1) Remember it**, same storage family as C1. Trade-off: one more small repository; users expect a chosen order to stick | **confirmed** (recommendation accepted) |
| G4 | What sort applies to | | **Applies to the TO DO section and to search results; COMPLETED keeps "most recently completed first"** (Phase 3 D2), because "newest created" is not meaningful for finished tasks. Trade-off: the sort does not touch the second section | **confirmed** (recommendation accepted) |
| G5 | Where the sorting rule lives | | **Extend Phase 3's pure ordering function in Domain with a `TodoItemSortOrder` parameter**, applied by the list view model, with tests per order and tie-breaks (due date, then oldest created; title ties by `createdAt`) | **confirmed** (recommendation accepted) |

### H. Interaction with Phase 5 and sequence
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| H1 | Search vs list filters | (1) search ignores the list's All/Active/Done/Category filter; (2) search respects it | **(1) Independent.** Search always covers every task; the active filter pill is untouched when search closes. Sort applies to both. Trade-off: searching while on "Done" still shows open tasks (clear and predictable) | **confirmed** (recommendation accepted) |
| H2 | Phase size and order | | **One macro phase** after Phase 5, internal order: sort order and ordering function, sort persistence and menu, `SearchQuery` and matcher, `SearchTodoItemsUseCase`, recent-search repository and use cases, view model, view and components, Add as task, router cover-over-cover | **confirmed** (recommendation accepted) |
| H3 | Project-file edits | | **None expected.** New files land in the synced `ToDoList/` folders, UserDefaults and Foundation are system frameworks, no new target or Info.plist change. If a decision above changes this, ask first | assumed |

## Scope (after decisions are confirmed)
- [x] `TodoItemSortOrder` and the ordering function extended with it (tests first); `SortOrderRepository` and its UserDefaults implementation
- [x] Sort menu on the list header; remembered choice
- [x] `SearchQuery` value object; `SearchTodoItemsUseCase` (title and description, case and diacritic insensitive, substring, optional category scope, completed included)
- [x] `RecentSearchRepository` with `UserDefaultsRecentSearchRepository`; use cases to list, record and clear
- [x] `TodoSearchViewModel` (recent, results, no results, scope, add-as-task prefill) tested first, no sleeps
- [x] Search entry button in the list header; `TodoSearchView` full-screen cover via the router (cover over cover for Add and Edit)
- [x] `SearchField`, `RecentSearchRow`, large `CategoryChip`, `EmptyStateIllustration`; previews for Recent, Results, No Results
- [x] Result row actions (toggle, open Edit, delete forwarded to the list's Undo toast)
- [x] `accessibility-check`; `design-fidelity-checker`; list the Sort menu as a designer follow-up

## Out of scope
- The "New category" sheet and custom categories (Phase 7); chips stay the three static categories
- Result highlighting, fuzzy search, saved searches, per-row delete of recents, search by due date
- Sort by category, manual ordering, sort indicator badge
- Steps progress on result rows (post-MVP), Smart add

## Done when
- Typing in search shows live results across titles and descriptions, ignoring case and accents, including completed tasks.
- Recent searches persist across launches (max 8, newest first, "Clear all" works), and a category chip shows that category's tasks.
- A query with no matches shows "No tasks found" and "Add “query” as a task" opens the Add form prefilled.
- The Sort menu orders the list and the choice survives a relaunch.
- Domain, repository and view model tests are green; the design-fidelity check shows no High differences for the three search frames.

## Build notes
- **Reused instead of new:** `CategoryChip(style: .option)` already was the larger chip (10x16, 14pt), `EmptyStateIllustration` already had a `.noResults` layout and `PrimaryButton` fit the "Add ... as a task" button, so F5's "size variant" and "illustration block" were not needed. New design-system pieces: `SearchField` and `SearchBar`, `RecentSearchRow`, `CircularIconButton` (Search and Sort header buttons), and a trailing link on `SectionHeader`.
- **Icons (SF Symbols):** `search` is `magnifyingglass`, `circle-x` is `xmark.circle`, `clock-3` is `clock`, `arrow-up-left` is `arrow.up.left`, `arrow-up-down` is `arrow.up.arrow.down`. `search-x` has no SF Symbol, so the No Results illustration uses `magnifyingglass`.
- **Added beyond the plan:** `GetSortOrderUseCase` and `SaveSortOrderUseCase` (a review found the list view model touching the repository directly), `PreviewDependencies` (preview wiring out of the views), and VoiceOver announcements for clearing recents and for toggling a result.
- **Composition root:** `AppDependencies` no longer defaults any repository; `ToDoListApp.make` builds the UserDefaults ones. `inMemory()` uses a throwaway suite.
- **Fidelity fixes after the check:** peach gradient background, a content-width "Add as task" button, vertically centered No Results content, lowercase query (auto-capitalization off), per-state spacing.
- **Process:** five agents built it in parallel worktrees (sort, search domain, components, view model, router and header button), then the screen. Cold builds in each worktree made every stream slow; one fix agent was stopped after 8 minutes and its pass was redone by hand.

## Follow-ups (not done in this phase)
- **Designer:** the Sort menu and an active-sort indicator, the selected category chip and the scope chip above results, the section rule color (`#E3CDB8` in the design, `border` token in the app), `search-x` icon, the 17pt field text and 16pt Cancel (app uses 16 and 15), the Recent header's 24pt height (app's "Clear all" keeps a 44pt hit area so the header is taller).
- **Accessibility, deferred:** the circular button outline (about 1.2:1) is decorative; a checkmark glyph on the selected chip; a multiline field for long queries at accessibility sizes; recent rows cost two VoiceOver stops each (one element plus a custom action would halve that); `CircularIconButton` icon does not scale with Dynamic Type; the escape gesture and the new announcements are untested with VoiceOver.
- **Untested view logic:** `TodoSearchView` and the nested-cover wiring in `TodoListView` have no unit tests (SwiftUI views; the logic is in the tested view model and router).
- **Manual check done on the simulator:** Recent, Results (live typing), No Results, Add as task opening prefilled over Search and returning with the new result. Not checked: Edit from a result, delete from a result (list Undo toast), keyboard return key behavior beyond focus, VoiceOver.
- **Process:** the new-announcement fix was one `feat:` commit with its `test:` commit before it; some reviewer-driven tests characterize existing behavior and passed on first run (no red step).
