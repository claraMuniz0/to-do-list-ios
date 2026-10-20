# Phase 2: Welcome / Empty Tasks

**Status:** done (all decisions confirmed and implemented)
**Design:** `to-do.pen`, frame "Welcome / Empty Tasks" (390x844)
**Depends on:** Phase 0 (project shell, `TodoItemRepository`), Phase 1 (tokens, `PrimaryButton`, illustration)

## Goal
The screen the user sees when there are no tasks, leading into creating the first one.

## What the design actually contains
- **Background:** vertical gradient, `#FFE8D6` at the top fading to `bg` (`#FFF8F0`) at 38%. A new token; it also runs under the status bar.
- **Header:** greeting "Welcome 👋" (Caveat 24, accent) above the title "My Tasks" (Fraunces 36, semibold **italic**, accent). The title is two text pieces in the design with the same style, so it is one `Text` in code.
- **Illustration (240x240) is drawn from shapes, not a single icon:** a 200pt `accent-soft` halo, a 140pt white disc with a warm shadow (`#D94A2B26`, y 8, blur 24), the 64pt `clipboard-check` icon in accent, and four decorative dots (coral 28pt accent, green 18pt `#7BC8A0`, peach 20pt `#FFC9B8`, blue 12pt `#B8C6FF`). This corrects the earlier Phase 1 note that said "a large icon in a decorative frame".
- **Copy:** title "Nothing to do yet" (Fraunces 26 bold, centered); description "Add your first task, then tap the circle whenever it's done." (Bricolage 16, width 290, line height 1.4, centered).
- **Button:** `PrimaryButton`, full width, label "Add your first task", plus icon. Pinned at the bottom (padding 8/20/32/20, gap 24); the empty state fills the space above it.
- **Not designed:** loading state, error state, and what the button opens in this phase (the Add Task form is Phase 3).
- The status bar (time, signal, wifi, battery) is system UI and is not drawn.

## Impact on earlier phases (applied to `phase-1-design-system.md`)
- **Phase 1 `EmptyStateIllustration`:** must support halo + disc + icon + dots, with the dot colors as tokens, not just icon-in-a-frame.
- **Phase 1 fonts:** this screen needs Fraunces **italic** (600) and **bold** (700), and Caveat semibold. The bundled font list must include those variants.
- **Phase 1 tokens:** add the background gradient top color, the disc shadow color and the three extra dot colors.

## Decisions
Recommendation in **bold**. Status `open` until confirmed.

### A. Behavior
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | When is the screen shown | (1) whenever there are zero tasks; (2) first run only, tracked by a stored flag | **(1) Zero tasks, always.** After deleting the last task the user returns here. A first-run flag adds persistence for no MVP benefit | **confirmed** (recommendation accepted) |
| A2 | What the button opens in this phase | (1) placeholder Add Task screen (title only), replaced in Phase 3; (2) nothing until Phase 3 | **(1) Placeholder**, so the navigation and the "Done when" are verifiable now | **confirmed** (recommendation accepted) |
| A3 | Loading state | (1) plain gradient background until the load finishes; (2) spinner; (3) show Welcome immediately | **(1) Plain background**, so the Welcome screen never flashes for users who already have tasks | **confirmed** (recommendation accepted) |
| A4 | Error state (load fails) | (1) minimal inline message + Retry; (2) crash/assert; (3) ignore | **(1) Minimal message + Retry** using existing components. Not in the design: you may want to design it later. Errors must never be swallowed | **confirmed** (recommendation accepted) |

### B. Structure
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Use case | (1) `GetTodoItemsUseCase` (wraps `allTodoItems()`); (2) view model calls the repository; (3) dedicated `HasTodoItemsUseCase` | **(1)**: view models never call repositories, and Phase 3's list needs the same use case | **confirmed** (recommendation accepted) |
| B2 | View model | (1) `TodoListViewModel` with a `ViewState` (loading / empty / loaded / error) introduced now; (2) throwaway `WelcomeViewModel` | **(1)**: Phase 3 adds the loaded content to the same view model instead of replacing it | **confirmed** (recommendation accepted) |
| B3 | Navigation | (1) introduce `NavigationStack` + route enum now (`AppRoute.addTodoItem`), per E2; (2) push a plain `NavigationLink` | **(1)**: the router is needed by Phases 3 and 4 anyway. Per Phase 3 A1, Add Task is presented as a **full-screen cover** driven by the router, so the placeholder is presented that way too | **confirmed** (recommendation accepted) |
| B4 | App entry | Rename the app entry point and remove the `ContentView` placeholder in this phase (A4 from Phase 0) | **Do it here**, when the first real root view exists. Composition root wires repository -> use case -> view model | **confirmed** (recommendation accepted) |

### C. UI
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Where the new tokens and illustration pieces live | (1) fold into Phase 1 (update its file); (2) add them in this phase | **(1) Fold into Phase 1**, so the design system is complete before screens use it | **confirmed** (recommendation accepted) |
| C2 | Layout at large Dynamic Type | (1) scrollable content with the button pinned at the bottom; (2) fixed layout | **(1)**: the illustration stays fixed size, text wraps, nothing clips | **confirmed** (recommendation accepted) |
| C3 | Accessibility | Illustration hidden from VoiceOver; "My Tasks" a header trait; greeting and title read in order; button label as shown | **As listed**; run `accessibility-check` | **confirmed** (recommendation accepted) |
| C4 | Strings | (1) English literals in code for the MVP; (2) String Catalog now | **(1) English literals**; localization later | **confirmed** (recommendation accepted) |

### D. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| D1 | Start order | **Phase 2 starts after Phases 0 and 1 are done** (needs the test target, `PrimaryButton`, tokens and fonts). Only Xcode project edits already flagged in those phases are needed; Phase 2 itself adds none | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [x] `GetTodoItemsUseCase` with tests (empty, non-empty, repository failure)
- [x] `TodoListViewModel` with `ViewState`, tested first (loading -> empty, loading -> loaded, failure, retry)
- [x] `AppRoute` + router; the button navigates to a placeholder Add Task screen
- [x] `WelcomeView`: gradient background, `ScreenHeader` (from Phase 1), composed illustration, copy, `PrimaryButton`
- [x] Minimal error view with Retry
- [x] Previews: empty, loading, error, empty at `.accessibility3`
- [x] Composition root; rename the entry point; delete the `ContentView` placeholder
- [x] `accessibility-check` and `design-fidelity-checker` pass

## Out of scope
- The Add Task form (Phase 3)
- The loaded task list, filters, "All caught up" (Phase 3 and post-MVP)
- First-run flags, onboarding, localization

## Done when
- A fresh install shows this screen with no flash of other content.
- The button opens the placeholder Add Task screen.
- View model and use case tests are green; the design-fidelity check shows no High differences.

## Build notes
- Use case, view model (`TodoListViewState`: loading / empty / loaded / error), `AppRouter` and the `AppDependencies.makeTodoListViewModel()` wiring are test-first. `AppDependencies` plus `live()` in `ToDoListApp.swift` together form the composition root.
- Views are not unit tested (pure rendering). Previews: empty, empty at `.accessibility3`, error, error at `.accessibility3`, placeholder. The loading state is the bare gradient.
- Reviews: design-fidelity found no High differences; fixed the vertical centering of the illustration block and the 16pt gaps. Accessibility: pinned button gets a `bg` background, error and placeholder views scroll, loading is labelled, error is announced, headers added.
- Design deviation, deliberate: button bottom padding is 8 plus the safe area (design draws 32 with no home indicator).
- Carried forward: SF Symbol `list.clipboard` vs design `clipboard-check` still unconfirmed; `PrimaryButton` icon is a fixed 18pt (does not scale with Dynamic Type); emoji in "Welcome 👋" is read aloud by VoiceOver; `TodoItemRepositorySpy` needs per-method errors and call counters in Phases 3-4; the view model drops the error cause (add typed error/logging once Data can really fail); `loaded` placeholder text is replaced in Phase 3; `dateProvider` is unused until Phase 3.
