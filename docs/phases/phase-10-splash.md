# Phase 10: Splash Screen

**Status:** done (all decisions confirmed and implemented)
**Design:** `to-do.pen`, frame "Splash" (390x844, id `aCsZH`)
**Depends on:** Phase 0 (composition root), Phase 1 (tokens, fonts), Phase 2 (`TodoListViewState.loading`). Independent of Phases 5 to 9.

## Goal
A branded screen shown while the app launches, handing off to Welcome, the list or the error view without a flash of other content.

## What the design actually contains
- **Background:** vertical linear gradient, `#E0603A` (top) to `#B03719` (bottom). Light content on a saturated coral; nothing like it exists in the tokens yet.
- **Decoration:** a radial white glow (620pt ellipse at -140,-200, `#FFFFFF33` fading to transparent), a 280pt outer ring (1.5pt stroke `#FFFFFF1F`, centered above the disc), and three dots: cream `#FFF8F0` 18pt, soft `#FFE3DA` 12pt, dark `#7A2610` 10pt.
- **Center block (vertical, gap 36, centered, bottom padding 40):** a 168pt cream disc (`#FFF8F0`, shadow `#5A1A0A66`, y 14, blur 36) holding the lucide `check` icon at 112pt in `#C4401F`; below it the tagline "one thing at a time" (Caveat 24, `#FFE3DA`).
- **Quirks:** the "Wordmark" frame holds only the tagline (no app name); the "Footer" frame (44pt) is empty. Both read as unfinished, so the design is taken as drawn: tagline only, nothing in the footer.
- **Not designed:** any motion, dark mode (the app forces light), a loading indicator, an error state.
- **Reuse:** the disc-plus-dots structure matches `EmptyStateIllustrationLayout` in spirit, but the colors, sizes, ring and glow differ, so it is a new view.

## Current repo state
- `TodoListView` renders `.loading` as the bare `welcomeGradient` labelled "Loading tasks" (Phase 2 A3). This phase replaces that.
- `TodoListViewModel.retry()` also goes through `.loading`, so the splash would reappear on retry unless the screen is told otherwise (see A3).
- The target already has `INFOPLIST_KEY_UILaunchScreen_Generation = YES` (white launch screen), so users see white, then the splash. Matching the launch screen to the splash needs a build-setting edit (see A1).
- `ToDoListApp` forces `.light`; no dark-mode work needed.

## Decisions
Recommendation in **bold**. Status `open` until confirmed.

### A. Behavior
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | Mechanism | (1) in-app `SplashView` plus a system launch screen set to a flat coral background (needs a build-setting / Info.plist edit, permission required); (2) in-app `SplashView` only, default white launch screen (no project edit, white flash first); (3) pre-rendered image as the launch screen (cannot scale to all devices, no project-free path) | **(1)**: a `UILaunchScreen` can only hold a color and an image, so the gradient, ring and Caveat tagline must be in-app anyway; the flat coral just removes the white flash. Falls back to (2) if the edit is declined | **confirmed** (recommendation accepted) |
| A2 | Duration | (1) until the first load finishes, no artificial delay; (2) short minimum (about 1s) | **(1)** was confirmed first; **changed to (2) after manual testing**: the local load finishes in milliseconds, so the splash was never seen. The first `load()` now holds `isLaunching` for at least 1s in total (injected `minimumLaunchDuration`, default 1s; `state` settles immediately; retries and reloads never wait) | **confirmed** (changed by the user after testing) |
| A3 | When it is shown | (1) every `.loading` including `retry()`; (2) first load of each cold start only; retry keeps the plain loading background | **(2)**: a retry after an error should not replay the brand screen. Needs a tested flag on the view model | **confirmed** (recommendation accepted) |
| A4 | Hand-off | (1) cross-fade (about 0.3s) to the next screen, instant when Reduce Motion is on; (2) hard cut always | **(1)**: smooth, and respects Reduce Motion | **confirmed** (recommendation accepted) |

### B. Structure
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Where the "launching" state lives | (1) `TodoListViewModel.isLaunching` (true until the first `load()` finishes), `TodoListView` shows the splash while true; (2) view-local `@State` flag set in `.task` | **(1)**: testable without a view, no new view model | **confirmed** (recommendation accepted) |
| B2 | Splash colors and gradient | (1) new tokens: colorsets plus `DSColor` entries and `DSGradient.splash`, tested like the existing ones (asset-catalog files only, no `.pbxproj`); (2) literals inside the view | **(1)**: same rule as Phase 2 C1 | **confirmed** (recommendation accepted) |
| B3 | Check icon | (1) SF Symbol `checkmark` at 112pt, compared in the fidelity check; (2) drawn `Shape` matching lucide `check` | **(1)**; (2) only if the fidelity check finds a High difference | **confirmed** (recommendation accepted) |

### C. UI
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Wordmark and footer | (1) as drawn: tagline only, footer empty; (2) add the "My Tasks" title; (3) ask the designer first | **(1)**; flag the single-child "Wordmark" frame and empty "Footer" to the designer | **confirmed** (recommendation accepted) |
| C2 | Decoration positions | (1) geometry as data relative to the disc center (like `EmptyStateIllustrationLayout`), so it holds on any screen size; (2) absolute 390x844 coordinates | **(1)**, with a test on the geometry | **confirmed** (recommendation accepted) |
| C3 | Accessibility | Decorative art hidden from VoiceOver; the screen exposes one element, "Loading tasks" (same label as today); tagline scales with Dynamic Type (art stays fixed); contrast of `#FFE3DA` on the gradient checked | **As listed**; run `accessibility-check` | **confirmed** (recommendation accepted) |

### D. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| D1 | Start order and project edits | **Build any time after Phase 2.** The only project-file edit is the launch screen background in A1; ask before touching it | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [x] Splash tokens (colorsets, `DSColor`, `DSGradient.splash`) with tests
- [x] `isLaunching` on `TodoListViewModel`, tested first (true before load, false after success, false after failure, unchanged by `retry()`)
- [x] `SplashLayout` geometry (disc, ring, dots) with tests
- [x] `SplashView` and the `TodoListView` hand-off (cross-fade, Reduce Motion)
- [x] Launch screen background (only if A1 option 1 is approved)
- [x] Previews: default, `.accessibility3`
- [x] `accessibility-check` and `design-fidelity-checker` pass

## Out of scope
- Motion beyond the hand-off fade, loading indicators
- Dark mode, localization of the tagline, app icon
- Onboarding or first-run flags

## Done when
- Cold start shows the splash, then the correct screen, with no flash of other content.
- Retry after an error does not show the splash.
- Reduce Motion is honored; tests green; accessibility check passes; design-fidelity shows no High differences.

## Build notes
- Test-first: tokens (8 colorsets, `DSColor`, `DSGradient.splash`, `DSFont.tagline`, `DSShadow.splash`), `TodoListViewModel.isLaunching` (cleared by a `defer` in `load()`, so `retry()` never re-arms it) and `SplashLayout` (offsets from the disc center). `SplashView` and the hand-off are not unit tested (pure rendering).
- Launch screen: `INFOPLIST_KEY_UILaunchScreen_BackgroundColor` is not a supported generated key (the dict stayed empty). Done instead with `Config/LaunchScreen-Info.plist` (`UILaunchScreen/UIColorName = splash-gradient-top`) plus `INFOPLIST_FILE` on both app-target configurations. It is flat coral `#E0603A`, so the bottom half jumps to the darker brick when the splash appears.
- Minimum duration: `TodoListViewModel(minimumLaunchDuration:)`, default `.seconds(1)`, `.zero` in the `makeSUT` test helper. Measured from the start of the first `load()`, so a slow load does not wait extra.
- Reviews: accessibility found no blockers; added a `ScreenChanged` post when the splash hands off. Fidelity found no High differences; horizontal padding fixed to 32.
- Carried forward: the SF `checkmark` (112pt, semibold) is larger and heavier than the design's lucide `check` (Medium, accepted per B3; a drawn `Shape` or about 90pt `.medium` would be closer). Tagline contrast is about 4:1 at its position (passes the 3:1 large-text rule; a lighter tint would read better in thin Caveat). The design's "Wordmark" and "Footer" frames still need the designer's word (C1). UI tests are done manually by the user.

