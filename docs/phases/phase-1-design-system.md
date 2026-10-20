# Phase 1: Design system components

**Status:** done (PR #3). Fonts bundled (OFL, licenses in `docs/licenses/fonts`, registered at runtime), app icon and app name "Do it later" set, visual check done on a real device
**Design:** `to-do.pen`, frame "Components" + the screens that use them
**Depends on:** Phase 0 (project structure, test target)

## Goal
Every reusable UI piece exists as a SwiftUI component driven by tokens, reviewable in one gallery screen, with no business logic.

## Decisions (all confirmed)
| # | Decision | Choice |
|---|----------|--------|
| P1-1 | Color tokens | Asset catalog color sets, exposed through a typed `Color` extension |
| P1-2 | Dark mode | Light only for the MVP (the .pen file only designs light); force light appearance, revisit post-MVP |
| P1-3 | Fonts | Bundle the files for Fraunces, Bricolage Grotesque, Outfit, Caveat, DM Mono; register in Info.plist. Needs project-file edits and a license check before bundling |
| P1-4 | Visual review | `#Preview` per component + one `DesignSystemGallery` screen showing all of them |
| P1-5 | Icons | SF Symbols mapped 1:1 from the design's Lucide icons (see table below) |
| P1-6 | Dynamic Type | Typography tokens scale with the user's text size; layouts must tolerate larger text |
| P1-7 | Variants | One SwiftUI component per design component, configured with parameters; no per-use wrappers |

## What the design actually contains
Several things in the design look like separate components but are one component with overrides:

| In the screens | Really is | SwiftUI shape |
|---|---|---|
| Save Button, Add First Task Button | Primary Button, different label/icon, full width | `PrimaryButton(title:systemImage:)` |
| Work/Personal/Shopping/New Category Option | Category Chip, larger padding, selection stroke | `CategoryChip(style: .tag / .option, isSelected:)` |
| Today / Tomorrow / Next week pills, All/Active/Done filters | Filter Pill, selected = accent fill | `FilterPill(isSelected:)` |
| Quick Add Input | Add Task Input, full width | `AddTaskInput` |
| Task Row (open) / Task Row Done | Two states of the same row | `TaskRow(task state)`, one component, two visual states |

## Tokens
**Colors:** bg `#FFF8F0`, surface, border, text-primary / secondary / muted, accent `#C4401F`, accent-soft, on-accent, danger, plus chip bg/fg pairs **keyed by palette color** (blue, brick, green now; violet, ochre, teal arrive in Phase 7), where Work, Personal and Shopping map to blue, brick and green. Done-row and toast use a few raw values (`#2B2118` toast, `#EFE6DA` done chip) that should become tokens.
**Typography:** heading Fraunces, body Bricolage Grotesque, UI Outfit, accent Caveat, mono DM Mono. Variants the screens need: Fraunces semibold **italic** (screen title 36) and bold (empty title 26), Caveat semibold (greeting 24). Bundle these variants (font files and Info.plist registration need project-file permission). Sizes seen: chip 12 (list) / 14 (option), pill 14, row title 16, button 17.
**Radii:** md 16, pill 999. **Shadows:** soft warm shadow on rows/inputs (`#EAD6C3`, y 3), accent shadow on buttons (`#8F2A10`, y 4).
**Touch targets:** checkbox 44×44 (ring 26), add button 44, more-options 40.

## Icon mapping (Lucide to SF Symbols)
| Design | SF Symbol |
|---|---|
| check | `checkmark` |
| plus | `plus` |
| trash-2 | `trash` |
| sliders-horizontal | `slider.horizontal.3` |
| sparkles | `sparkles` |
| clipboard-check (proposal, unconfirmed) | `list.clipboard` |
| party-popper (proposal, unconfirmed) | `party.popper` |
| search-x (proposal, unconfirmed) | `magnifyingglass` |
| list-checks (proposal, unconfirmed) | `checklist` |

The design uses about 25 Lucide icons in total (status-bar signal/wifi/battery are system UI and are not drawn). Only the five above are mapped now. Each later phase adds the icons it needs to this table, including the three illustration icons (`clipboard-check`, `party-popper`, `search-x`).

## Images
The design has no bitmap or custom artwork: every "illustration" is a large icon in a decorative frame, plus the 👋 emoji on the Welcome screen. No image assets are added in this phase.
- Asset catalog holds only color sets for now.
- **App icon: not designed.** Left open; decide before any TestFlight/device build.
- If custom illustrations are wanted later, export them from the design and add them post-MVP.

## Scope
### Tokens
- [x] Color sets in the asset catalog + `Color` extension (names mirror the .pen variables)
- [x] Font registration + typography tokens that scale with Dynamic Type
- [x] Radius and shadow tokens (incl. illustration disc shadow `#D94A2B26`, y 8, blur 24)
- [x] Toast tokens: background `#2B2118`, Undo color `#FFB4A0`; the toast uses Outfit (`font-ui`) for the message and Undo, not DM Sans (Phase 4 C4)
- [x] Welcome background gradient: top `#FFE8D6` to `bg` at 38% (`DSGradient.welcome`)
- [x] Illustration dot colors: green `#7BC8A0`, peach `#FFC9B8`, blue `#B8C6FF` (coral is `accent`)
- [x] Promote the loose raw values (toast, done chip) to named tokens

### Components
- [x] `CategoryChip` (tag and option styles, selected state)
- [x] `PrimaryButton` (icon + label, full-width option, **disabled state**: opacity 0.4 (changed from 0.6 in Phase 3, E3), no shadow)
- [x] `FilterPill` (selected state)
- [x] `ScreenHeader` (subtitle in Caveat accent + italic Fraunces title; used by Welcome, Add Task and Task List)
- [x] `AddTaskInput` (placeholder, options button, add button)
- [x] `TaskRow` (open and done states, optional description, category chip, step count slot unused in MVP)
- [x] `UndoToast` (message + Undo action)
- [x] `EmptyStateIllustration`: composed from shapes, not a single icon: 200pt `accent-soft` halo, 140pt white disc with warm shadow, a 64pt SF Symbol in accent, and 4 decorative dots (coral 28, green 18, peach 20, blue 12). Parameters: symbol, size, dot set. Reused by Welcome `clipboard-check`, All Done `party-popper`, Search No Results `search-x` (48pt; check in the design whether it uses the same composition)
- [x] `DesignSystemGallery` screen

### Tests
Visual components are mostly previews; test only logic: token lookups return the expected colors, category to chip-style mapping, and row state to visual style mapping.

## Out of scope
- Screen layouts, navigation, view models
- Sheets (date, category, steps) and the Scrim: built with their screens in Phase 3 and later
- Dark mode, iPad layouts, Lucide assets, custom images, app icon

## Open items (not decisions, just checks)
- Confirm the license of each Google Fonts family before bundling (all five are open licenses, verify)
- Contrast: `text-muted` `#7D6E61` on `bg` `#FFF8F0` and chip colors should be checked against WCAG AA when building

## Done when
- The gallery screen renders every component in every state, in a light-only app.
- Token and mapping tests are green.
- Nothing in Domain depends on this layer.

## Build notes
- Colors live in the asset catalog (`DSColor`, `ChipPalette`); added tokens beyond the design variables: `border-control` (`#8E8272`, a stronger edge for form fields because `border` is ~1.2:1), `toast-shadow`, `done-chip-bg`, `shadow-soft`, `shadow-accent`.
- Fonts are variable files registered at runtime by `FontRegistrar` (no Info.plist or project edit). Bricolage Grotesque defaults to optical size 96 (display cut), so its tokens are built through UIKit with `opsz` matched to the point size (`DSFont.uiFont(for:)`).
- Shadows are cast from the background shape only (`dsBackground`) so text and icons never get one.
- Disabled `PrimaryButton`: opacity 0.4 (was 0.6; changed in Phase 3, E3), no shadow.
- `FilterPill` is 44pt tall (the design is ~36pt) to meet the touch-target rule.
- `EmptyStateIllustration` takes a `layout:` (`.welcome`, `.celebration`, `.noResults`) because the design uses three geometries.
- Project-file edits made with permission: `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` and `INFOPLIST_KEY_CFBundleDisplayName = "Do it later"`.
- Simulator text can look soft; checked on a real device and it renders fine.

- Layout: the design system lives in `ToDoList/Shared/DesignSystem/` (Tokens, Components, Gallery, Fonts), outside `Presentation`, because it is feature-agnostic; tests mirror it in `ToDoListTests/Shared/DesignSystem/`. `Presentation` depends on it, never the reverse.

## Carried forward
- "+ New" option chip (surface fill, border, accent text) is not a palette chip: Phase 7.
- Toast VoiceOver announcement and option-chip button traits belong to the screens that host them.
- SF Symbols for the illustrations (`list.clipboard`, `party.popper`, `magnifyingglass`) and `checklist` are unconfirmed proposals.
