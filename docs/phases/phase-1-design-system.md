# Phase 1: Design system components

**Status:** not started (decisions confirmed, ready to start after Phase 0)
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
**Colors:** bg `#FFF8F0`, surface, border, text-primary / secondary / muted, accent `#C4401F`, accent-soft, on-accent, danger, plus chip pairs for work, personal, shopping (bg + fg). Done-row and toast use a few raw values (`#2B2118` toast, `#EFE6DA` done chip) that should become tokens.
**Typography:** heading Fraunces, body Bricolage Grotesque, UI Outfit, accent Caveat, mono DM Mono. Sizes seen: chip 12 (list) / 14 (option), pill 14, row title 16, button 17.
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

The design uses about 25 Lucide icons in total (status-bar signal/wifi/battery are system UI and are not drawn). Only the five above are mapped now. Each later phase adds the icons it needs to this table, including the three illustration icons (`clipboard-check`, `party-popper`, `search-x`).

## Images
The design has no bitmap or custom artwork: every "illustration" is a large icon in a decorative frame, plus the 👋 emoji on the Welcome screen. No image assets are added in this phase.
- Asset catalog holds only color sets for now.
- **App icon: not designed.** Left open; decide before any TestFlight/device build.
- If custom illustrations are wanted later, export them from the design and add them post-MVP.

## Scope
### Tokens
- [ ] Color sets in the asset catalog + `Color` extension (names mirror the .pen variables)
- [ ] Font registration + typography tokens that scale with Dynamic Type
- [ ] Radius and shadow tokens
- [ ] Promote the loose raw values (toast, done chip) to named tokens

### Components
- [ ] `CategoryChip` (tag and option styles, selected state)
- [ ] `PrimaryButton` (icon + label, full-width option)
- [ ] `FilterPill` (selected state)
- [ ] `AddTaskInput` (placeholder, options button, add button)
- [ ] `TaskRow` (open and done states, optional description, category chip, step count slot unused in MVP)
- [ ] `UndoToast` (message + Undo action)
- [ ] `EmptyStateIllustration` (SF Symbol + size + tint inside a decorative frame; reused by Welcome `clipboard-check` 64pt, All Done `party-popper` 64pt, Search No Results `search-x` 48pt)
- [ ] `DesignSystemGallery` screen

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
