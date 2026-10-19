# Phase 7: Custom Categories

**Status:** not started (all decisions confirmed, ready to start after Phase 5)
**Design:** `to-do.pen`: "New Category Sheet" (the sheet frame "Category Sheet" over its scrim, shown on top of the list), "Add Task" and the Edit frames (the "+ New" option in the Category field), "Task List – Categories" (the "New category" row)
**Depends on:** Phase 3 (Category, form, SwiftData repository, composition root), Phase 4 (Edit form, mode-based form view model), Phase 5 (Categories filter), Phase 1 (`CategoryChip`, tokens)

## Goal
Let the user create their own categories (name + color, with a live preview), choose them on tasks, and see them in the category filter, without breaking the three built-in ones.

## What the design actually contains
**Category Sheet (bottom sheet, 390x439, `surface`, with a 50% `#2B2118` scrim)**
- Grabber, title row "New category" (Fraunces 26) with a 40x40 Close (X) button on `bg`.
- **Name** label (Outfit 14, `text-secondary`) and a 54pt input in its focused state (2pt `accent` inner stroke, caret, typed text "Health", Bricolage 17). No placeholder, counter or error is designed.
- **Color** label and a row of **6 swatches**, 40x40 circles: Blue `#3449A8`, Brick `#A83A1F`, Green `#27704A`, Violet `#8A4FB5`, Ochre `#B7791F`, Teal `#0F7C8A`. The selected one (Green) is a 40pt `surface` ring with a 2pt stroke in its color, a 30pt filled circle inside and a white check icon (16pt). Selection is shown by ring and check, not by color alone.
- **Preview** label and a live `Category Chip` instance showing the typed name ("Health") in the selected color pair: `#DDF3E4` background, `#27704A` text, Outfit 12 semibold.
- Full-width pill button, `accent` fill, check icon, label **"Create category"** (not "Create"). No disabled state designed.
- The sheet has no keyboard in the frame, so how it rises with the keyboard is undesigned.

**Where the sheet appears in the design:** the only frame shows it over the **Task List** (opened from the "New category" row in the Categories filter). There is **no frame of the sheet over the Add or Edit form**. We reuse the same sheet there (see decision E1).

**"+ New" in the forms (Add Task and the Edit frames)**
- A fourth option in the Category chips row: `Category Chip` in its option style with `surface` fill and `border` stroke, label "+ New" (71x38, no color pair). Work, Personal and Shopping use their pairs; the selected one has an `accent` stroke.

**"New category" row in "Task List – Categories" (Phase 5)**
- A 48pt row, `accent-soft` fill, plus icon and "New category" (Outfit 16, `accent`), placed under the Shopping row and above the "SHOWING · WORK" section. Category rows show a 14pt color dot, name, "N tasks" (DM Mono 12) and a select indicator (filled accent circle with check when selected, an empty ring otherwise).

**Design discoveries**
- The palette is **solid colors only (6)**; there are no background/foreground pairs for the custom colors. Chip pairs exist only for the first three (Blue = Work, Brick = Personal, Green = Shopping). The pair for Violet, Ochre and Teal must be derived (decision D1).
- The three built-in category colors equal the first three swatches exactly, so the built-ins can be expressed as palette colors with no extra tokens.
- **Contrast of the swatch colors as chip text** (measured, WCAG 2 ratio vs `#FFFFFF` / vs a 12% tint of itself): Blue 7.9 / 6.5, Brick 6.4 / 5.3, Green 6.0 / 5.1, Violet 5.4 / 4.6, Teal 4.9 / 4.2, **Ochre 3.6 / 3.2**. Chip text is 12pt, so it needs 4.5:1. **Ochre fails and Teal fails on a tint**: those two need a darker foreground than the swatch color (decision D1). The existing three pass on their designed backgrounds (6.6, 5.2, 5.1).
- Button copy is "Create category"; the button's disabled state, a duplicate-name error, an empty-name state for the Preview chip and the "max length" behavior are **not designed**.
- Rename, delete, and edit color of a category are **not designed**. The Categories filter shows no menu or swipe on rows.
- The sheet's name for design reference is "Category Sheet" (child of the frame "New Category Sheet"); the backlog calls it the "Create-category sheet".
- The Categories filter in the design looks single-select ("SHOWING · WORK"); that is Phase 5's call, not this phase's.

## Impact on earlier phases (to apply once decisions are confirmed)
- **Phase 3 (most important, must be decided BEFORE Phase 3 is built):**
  - B8 chose a static seeded set stored by key. This phase makes Category a persisted entity. To avoid any SwiftData migration, Phase 3 must already store the category on `TodoItemRecord` as a **plain `String` id** (`categoryID`), never as an enum, never as a `@Relationship`, and never as name or color. With that, `TodoItemRecord` does not change in Phase 7: only a new `CategoryRecord` model is added to the schema, which SwiftData handles as an additive (lightweight) change (see C1 to C3).
  - Phase 0 C2 says `Category` is a value with name + color key. Phase 3 should add a `CategoryID` value object (string, built-ins use stable ids `work`, `personal`, `shopping`) and `Category` = id + `CategoryName` + `CategoryColor`.
  - `TodoItemMapper` must not hardcode the three categories. It should receive a category lookup (`(CategoryID) -> Category`) with a defined fallback for an unknown id (decision B4). In Phase 3 that lookup is just the seeded three.
  - Phase 3 C4 ("no schema versioning") stays valid for Phase 7 if the points above hold.
- **Phase 1:** `CategoryChip` and the tokens should be keyed by **palette color** (blue, brick, green, violet, ochre, teal), not by category (work, personal, shopping). Work/Personal/Shopping map to blue/brick/green. Rename the `chip-work-*` style tokens at build time (the `.pen` names are a design detail) and add three pairs. The planned "category to chip-style mapping" test then takes a `CategoryColor`.
- **Phase 4:** the Edit form already reuses the Add form view model, so the "+ New" chip and sheet come for free once built there; editing a task keeps working if its category was deleted (B4).
- **Phase 5:** the Categories filter lists categories from the `CategoryRepository` (not a hardcoded three) and shows the "New category" row that opens this sheet. Phase 5's question "do the Categories rows include New category" is answered here: yes, but wired in Phase 7 (decision E3).
- **PLAN.md and the backlog:** a new "Phase 7: Custom Categories" entry replaces the backlog bullet "Create-category sheet". Not edited here; apply after you confirm. Phase 6 (Search and sort) is not touched.
- **Xcode project file:** none required by anything here. Sources live in the synced `ToDoList/` folder (Phase 0), SwiftData is a system framework, colors can be code tokens. Adding color sets in `Assets.xcassets` (if D3 chooses that) is a file change inside the asset catalog, not a project-file edit. No decision below needs `.pbxproj` changes.

## Decisions
Recommendation in **bold**. Status `open` until you answer (this kickoff could not ask questions). Rows marked `assumed` are small and non-blocking; say if you disagree.

### A. Scope and structure
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| A1 | What the phase includes | (1) create + list only; (2) create, list, rename, delete | **(1) Create and list only.** Rename and delete are not designed, and delete forces a "what happens to its tasks" rule. Trade-off: users cannot fix a typo or remove a category until a later phase | **confirmed** (recommendation accepted) |
| A2 | Built-in categories | (1) Work, Personal, Shopping stay built in: not renameable, not deletable, stable ids; (2) become normal editable records | **(1) Built-in.** Keeps Phase 3 untouched and the stable ids safe; trade-off: they cannot be customized | **confirmed** (recommendation accepted) |
| A3 | Phase size and order | (1) one phase: domain, repository, sheet, form wiring, filter row; (2) split data + domain from UI | **(1) One phase**, internal order: domain and value objects, repository and persistence, sheet view model, sheet view, "+ New" in forms, filter row. Trade-off: it is the largest piece; split later if it drags | **confirmed** (recommendation accepted) |
| A4 | Optional later work (only if A1 = (2)) | `RenameCategoryUseCase`, `DeleteCategoryUseCase` and its reassign rule | **Not built now.** Rule if added later: tasks move to Personal (a delete never deletes tasks) | **not built now** (follows A1) |

### B. Domain
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Category shape | `Category` = `CategoryID` + `CategoryName` + `CategoryColor`, immutable value type | **As described.** `CategoryID` wraps a `String`: built-ins use `work`, `personal`, `shopping`; custom ones use a generated UUID string. Trade-off: a string id is less type-strict than a UUID, but it is what keeps `TodoItemRecord` unchanged | **confirmed** (recommendation accepted; applied to Phases 1 and 3) |
| B2 | `CategoryName` value object | trimmed, non-empty, max length, unique | **Trimmed, non-empty, max 20 characters** (a long name makes a chip and the filter row wrap); the field stops input at 20, as for the title. Trade-off: 20 is a guess; the design shows 6 characters | **confirmed** (recommendation accepted) |
| B3 | Uniqueness | (1) case- and diacritic-insensitive, including the built-ins; (2) exact match | **(1) Insensitive**: "work", "Work " and "WORK" collide. Checked in the use case against the repository (the value object only validates the name itself). Error `CategoryError.duplicateName` | **confirmed** (recommendation accepted) |
| B4 | A task whose category cannot be found | (1) fall back to Personal; (2) a visible "Uncategorized" | **(1) Fall back to Personal** in the mapper lookup, covered by a test, never a crash. It cannot happen with A1 = (1) but protects against corrupt or future data. Trade-off: hides a data problem | **confirmed** (recommendation accepted; applied to Phases 1 and 3) |
| B5 | `CategoryColor` | (1) enum of the 6 palette keys, `allCases` in palette order; (2) free hex string | **(1) Enum of 6 keys** (blue, brick, green, violet, ochre, teal). Domain holds only the key; the actual colors live in Presentation tokens (pure Domain). Trade-off: adding a color is a code change | **confirmed** (recommendation accepted) |
| B6 | Use cases | `CreateCategoryUseCase` (validates, checks uniqueness, adds), `ListCategoriesUseCase` (built-ins then custom) | **As described**, named `<Verb><Noun>UseCase`, each tested first with a hand-written `CategoryRepository` double | **confirmed** (recommendation accepted) |
| B7 | Ordering | (1) built-ins in the design order (Work, Personal, Shopping), then custom by creation order; (2) all alphabetical | **(1) Built-ins first, then custom oldest first**; "+ New" always last in the chips row. Needs `createdAt` on the category record (via `DateProvider`). Trade-off: a long list is not alphabetical | **confirmed** (recommendation accepted) |
| B8 | Maximum number of categories | (1) none; (2) a cap (for example 12) | **(1) None** (YAGNI). The chips row wraps or scrolls (E5) | assumed |
| B9 | Category on completed or existing tasks after create | nothing changes | **Nothing changes.** Creating a category never touches existing tasks | assumed |

### C. Data and persistence
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Storage of custom categories | (1) new `@Model CategoryRecord` (id, name, colorKey, createdAt) mapped by `CategoryMapper`; (2) store in `UserDefaults` | **(1) SwiftData `CategoryRecord`**, same container and mapping rules as Phase 3 C1. Trade-off: one more model, but no second persistence mechanism | **confirmed** (recommendation accepted) |
| C2 | Where the built-ins live | (1) static in Domain, merged in front of the stored custom ones by the repository; (2) seeded as rows on first launch | **(1) Static, merged.** No seeding code, no first-launch race, and built-ins cannot be lost or edited. Trade-off: the repository's list is "static + stored", so the id space must not collide (custom ids are UUIDs) | **confirmed** (recommendation accepted) |
| C3 | Schema change and migration | (1) none needed: `TodoItemRecord` keeps `categoryID: String`; adding `CategoryRecord` is additive; (2) `VersionedSchema` + migration plan from Phase 3 on | **(1) No versioned schema**, provided Phase 3 stores the category as a plain string id (see Impact on Phase 3). If Phase 3 stored an enum, a relationship, or name/color, this phase would need a migration plan. Trade-off: if the stored shape ever changes later, a versioned schema must be introduced then | **confirmed** (recommendation accepted; applied to Phases 1 and 3) |
| C4 | Repository | `CategoryRepository` protocol in Domain (`all()`, `add(_:)`), `@MainActor` `SwiftDataCategoryRepository` in Data, an in-memory double for tests and previews | **As described**, same container as the to-dos (Phase 3 C2, C3). Only the methods this phase uses (`all`, `add`); `rename` and `delete` are not added | **confirmed** (recommendation accepted) |
| C5 | Task counts for the filter rows ("2 tasks") | (1) computed by Phase 5 from the loaded to-dos; (2) a repository count query | **(1) Phase 5 computes them** from the list it already has. Not part of this phase | assumed |

### D. Palette and tokens
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Palette | (1) the 6 colors in the design; (2) more colors; (3) a color picker | **(1) The 6 designed colors.** Derive each chip pair as tokens (not computed at runtime): `fg` = the color (darkened where needed), `bg` = a light tint. Keep the three existing designed pairs exactly. Measured need: **Ochre `#B7791F` and Teal `#0F7C8A` as text on a tint fail 4.5:1**, so give Ochre (and Teal, Violet if their tint also fails) a darker `fg` for the chip text while the swatch and dot keep the designed color. Trade-off: chip text and swatch differ slightly for those two; flag the new pairs to the design | **confirmed** (recommendation accepted) |
| D2 | Who owns the pairs | tokens in Presentation keyed by `CategoryColor`: `swatch`, `chipForeground`, `chipBackground`, `dot` | **As described**; one place, covered by a token lookup test (Phase 1 style) | **confirmed** (recommendation accepted) |
| D3 | Where token values live | (1) Swift constants like the Phase 1 tokens; (2) asset-catalog color sets | **(1) Same mechanism as Phase 1 tokens** (assumed). Asset-catalog files, if Phase 1 uses them, are not a project-file edit | assumed |

### E. Presentation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| E1 | Where the sheet is shown | (1) one reusable `NewCategorySheet`, a sheet presented over the Add/Edit full-screen cover and over the list; (2) a router route | **(1) One reusable sheet**, local presentation state in the presenting view model (`isPresentingNewCategory`), `NewCategoryViewModel` built by a factory in the composition root. The design only shows it over the list; over the form is our extension. Trade-off: not router-driven, unlike Add/Edit (those are full-screen covers) | **confirmed** (recommendation accepted) |
| E2 | Sheet size and keyboard | (1) fixed detent matching 439pt, name field focused on open, content scrolls above the keyboard; (2) large detent | **(1) Height detent** with the field auto-focused (as the design's focused state). Undesigned: keyboard overlap, so the sheet grows to the keyboard height | **confirmed** (recommendation accepted) |
| E3 | After Create | (1) the sheet returns the new `Category` to its presenter and dismisses; the form selects it, the filter list reloads; (2) the sheet only dismisses and the presenter reloads | **(1) Return the created category.** In a form: select it as the task's category. In the Categories filter: refresh the rows and leave the current filter selection alone (Phase 5 may choose otherwise). Trade-off: the presenter must handle a result | **confirmed** (recommendation accepted) |
| E4 | Create button and validation | (1) disabled until the name is valid; inline error text only for a duplicate name; (2) enabled always, error on tap | **(1) Disabled until valid** (reuses Phase 3 E3 disabled style). For a duplicate, an inline `danger` message under the field ("A category with this name already exists") and Create stays disabled. Both undesigned; flag to the design | **confirmed** (recommendation accepted) |
| E5 | Chips row with many categories | (1) horizontal scroll with "+ New" last; (2) wrapping rows | **(1) Horizontal scroll**, keeping the form height stable. Trade-off: "+ New" can be offscreen when the list is long (mitigated by scrolling to the new chip after Create) | **confirmed** (recommendation accepted) |
| E6 | Default selected color | (1) first palette color (Blue); (2) first color not used by an existing category | **(1) Blue**, deterministic and simple. The design shows Green selected as an example only. Trade-off: duplicates of color are allowed | **confirmed** (recommendation accepted) |
| E7 | Empty name in the Preview chip | (1) placeholder text "Category" in muted style; (2) hide the chip | **(1) Placeholder "Category"**, chip keeps the selected color. Undesigned | assumed |
| E8 | Closing the sheet with typed input | (1) just close (Close X, scrim tap and swipe down all discard); (2) confirm | **(1) Just close** (as Phase 3 A6) | assumed |
| E9 | Accessibility | swatches are buttons labelled with the color name ("Blue") and the selected trait; the check stays the non-color signal; the Preview chip reads its text; swipe-down and Close X both dismiss; 44pt targets (the 40pt swatches get a larger hit area); duplicate error announced | **As described**; run `accessibility-check` (the design's swatches are 40pt, below 44). Category color is never the only signal: chips and rows always carry the name | **confirmed** (recommendation accepted) |
| E10 | Chip option "+ New" | a new `CategoryChip` style `.newOption`, or the `.option` style with a plus icon | **A `.newOption` style** (dashed or `surface` fill with `border`, as designed) added to the Phase 1 `CategoryChip`; not selectable, it only opens the sheet | **confirmed** (recommendation accepted) |

### F. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| F1 | When to build | **After Phase 5** (the filter row needs the Categories filter) and independent of Phase 6. The form half could ship earlier, but the sheet is only designed over the list | **confirmed** (recommendation accepted) |
| F2 | What to settle before Phase 3 is built | Decisions B1 (string `CategoryID`, stable built-in ids), B4 (mapper lookup with fallback) and C3 (record stores `categoryID: String`) must be reflected in the Phase 3 file before its implementation starts; they avoid any migration | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] Domain: `CategoryID`, `CategoryName`, `CategoryColor`, `Category` (built-ins `work`, `personal`, `shopping`), `CategoryError`, each tested first
- [ ] `CategoryRepository` protocol, `CreateCategoryUseCase`, `ListCategoriesUseCase`, with a hand-written test double
- [ ] Data: `CategoryRecord`, `CategoryMapper`, `SwiftDataCategoryRepository` (in-memory container tests), composition root registration; mapper category lookup with fallback
- [ ] Tokens: palette pairs for the 6 colors (contrast checked), `CategoryChip` `.newOption` style
- [ ] `NewCategoryViewModel` (name, color, validity, preview, duplicate error, create) tested first
- [ ] `NewCategorySheet` (grabber, title, name, swatches, Preview chip, "Create category"), previews per state
- [ ] "+ New" in the Add and Edit forms: opens the sheet, selects the new category
- [ ] "New category" row in the Categories filter (Phase 5): opens the sheet, refreshes rows
- [ ] `accessibility-check`; `design-fidelity-checker`

## Out of scope
- Rename, delete, reorder or recolor a category (unless A1 = (2))
- Search and sort (Phase 6), steps, Smart add, "Break it down"
- Category icons, emoji, a free color picker, a category cap
- Syncing categories across devices

## Done when
- The "+ New" chip (forms) and the "New category" row (filter) open the sheet; a valid name and color create a category that survives a relaunch.
- The new category is selected in the form, shows as a chip with its color pair, and appears in the Categories filter.
- Built-in categories and all earlier tasks are unchanged after the update, with no data migration.
- Name rules (trim, empty, max length, duplicates) are covered by tests; the chip color pairs pass 4.5:1; the design-fidelity check shows no High differences.
