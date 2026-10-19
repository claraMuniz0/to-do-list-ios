---
name: new-ds-component
description: Scaffold ONE design-system SwiftUI component (e.g. CategoryChip, PrimaryButton, FilterPill, TaskRow, UndoToast) in the to-do iOS app. Trigger when asked to create, add, or build a design-system / reusable UI component, or a new variant of one. Not for screens, view models, or sheets.
---

# New design-system component

Source of truth: `docs/phases/phase-1-design-system.md` (decisions P1-1..P1-7 are binding). Light mode only.
Assumed location (adjust to actual repo layout): `ToDoList/Presentation/DesignSystem/`, tests mirrored under the test target.

## Before writing
- [ ] Check the design-to-component table in the phase doc. If the request is really an override of an existing component (Save Button = PrimaryButton, Category Option = CategoryChip, Today Pill = FilterPill), extend that component with a parameter. Do not create a wrapper.
- [ ] If no written spec exists, run `design-to-swiftui-spec` first.
- [ ] Do not install packages or edit Xcode project files (new file references, font registration) without explicit permission; ask.

## Build
- [ ] One `struct <Name>: View` per design component. Variants via parameters (enum style, `isSelected`, optional icon/label), never per-use wrappers.
- [ ] Value types, no business logic, no Domain imports beyond plain display data passed in.
- [ ] Tokens only: colors via the typed `Color` extension (asset catalog), fonts via typography tokens, radii/shadows via tokens. No raw hex, no font-name strings, no magic numbers that a token covers. If a value is missing, add a token (and flag it) instead of inlining.
- [ ] Fonts must be Dynamic Type-scaling tokens (e.g. `relativeTo:` text style). Layout must tolerate larger text: no fixed heights on text containers, allow wrapping/`lineLimit` deliberately.
- [ ] Icons: SF Symbols per the mapping table in the phase doc (check -> `checkmark`, plus -> `plus`, trash-2 -> `trash`, sliders-horizontal -> `slider.horizontal.3`, sparkles -> `sparkles`). If a needed Lucide icon is unmapped, pick the closest SF Symbol, add the row to the table in the phase doc, and mention it.
- [ ] Interactive elements: hit area at least 44x44pt (`.frame(minWidth: 44, minHeight: 44)` + `.contentShape`). Visual size may be smaller than the hit area.
- [ ] Accessibility: label for icon-only controls, `isSelected` trait where relevant.
- [ ] Light only: do not add dark variants; the app forces light appearance.

## Previews and gallery
- [ ] `#Preview` for EVERY state/variant (default, selected, done, disabled, long text, etc.), each named.
- [ ] Add the component, in every state, to `DesignSystemGallery`.

## Tests (TDD, logic only)
- [ ] Write the failing test first (Swift Testing, file `<Name>Tests.swift`, mirrored folder), commit `test:`.
- [ ] Test only logic: token lookup returns expected color/font, state -> style mapping (e.g. category -> chip colors, row state -> visual style). Extract such logic into a small pure type/enum so it is testable.
- [ ] No snapshot or view-hierarchy tests for pure layout.
- [ ] Cover edge cases: unknown/empty values, every enum case.
- [ ] Then implement minimum, green, commit `feat:`; refactor in `refactor:`.
- [ ] Doc comments only afterwards, in a separate `docs:` commit, only for non-obvious WHY.

## Done when
Previews render all states, gallery shows them, token/mapping tests green, no raw hex/font names (grep the new files to confirm), nothing in Domain depends on this layer.
