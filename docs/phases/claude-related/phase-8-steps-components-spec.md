# Phase 8: Steps components spec (from `to-do.pen`)

Spec only, no code. Source frames: "Edit Task – Steps" (`zZdaQ`), plus the Steps Field instances in Smart Add Review (`e70Bfm`) and the Task Row (`v5TN3`).

## 1. Target
- **Steps Field** (`RZjxs`, 350x366 inside Edit Task): header, progress track, list of step rows, "Add a step" row. Same component set is reused by Smart Add Review (`e70Bfm`: no progress bar, tag "3 steps" instead of the count).
- **Task Row steps progress** (`jUq0s`, currently `enabled: false` in the master row): icon + "2/5".
- Build order: `StepRow` → `StepsProgressBar` → `SuggestPill` → `StepsField`.

## 2. Tokens used (all already bound to variables, nothing raw)
| Use | Token | Existing `DSColor` / metric |
|-----|-------|-----------------------------|
| Label "Steps" | `$text-secondary`, `$font-ui` 14/600 | `DSColor.textSecondary` |
| Count "2 of 5" | `$text-muted`, `$font-mono` 12 | `DSColor.textMuted` |
| Pill fill / stroke / text | `$accent-soft`, `$accent` 1pt inner, `$accent` | `DSColor.accentSoft`, `.accent`, radius `DSRadius.pill` |
| Track / fill | `$border` / `$accent`, both radius 3 | `DSColor.border`, `.accent` |
| List card | `$surface`, `$border` 1pt, `$radius-md` (16), padding `[0,18]` | `DSColor.surface`, `DSRadius.md` |
| Row divider | `$border` 1pt bottom only | `DSColor.border` |
| Checkbox done | fill + 2pt inner stroke `$accent`, check icon `$on-accent` | `DSColor.accent`, `.onAccent` |
| Checkbox open | fill `$surface`, 2pt inner stroke `$border` | `DSColor.surface`, `.border` |
| Step text | `$font-body` 16, `$text-primary` (open) / `$text-muted` (done) | `DSColor.textPrimary`, `.textMuted` |
| Grip, "Add a step" text | `$text-muted` | `DSColor.textMuted` |
| Row progress | `$font-ui` 12/600, `$text-muted` | `DSColor.textMuted` |

## 3. Layout
| Element | Spec |
|---------|------|
| Steps Field | vertical, gap 10, full width (350 in the 390 frame, 20pt margins) |
| Header | horizontal, gap 8, height 28: label, count, spacer, pill |
| Pill | 125x28, padding `[6,12]`, gap 6, sparkle 14, label 13/600 |
| Progress track | 350x6, radius 3; fill width = `fraction * trackWidth` (140/350 = 2 of 5), same radius |
| Step row | height 52, padding `[14,0]`, gap 14, bottom divider, 24pt checkbox, text fills, 16pt grip trailing |
| Checkbox | 24x24 circle, 2pt inner stroke, check icon 14 |
| "Add a step" row | same 52pt row, no divider, 24x24 frame holding an 18pt plus (accent), placeholder text 16 `$text-muted` |
| Touch targets | design shows 24pt checkbox and 16pt grip: **hit areas must be 44x44** (checkbox leading, grip trailing), visual size unchanged |

## 4. States and variants
| Component | States |
|-----------|--------|
| Step row | open (surface checkbox, primary text), done (accent checkbox with check, muted text, **no strike-through**, same rule as `TaskRowStyle`) |
| Steps header | count "N of M" with progress bar; `tag` variant ("3 steps", no bar) for Smart Add Review |
| Suggest pill | idle; loading (spinner replaces sparkle, disabled); hidden when `ClaudeAvailability` is false |
| Progress bar | 0 steps: component hidden (progress is `nil`); 0 done: empty track; all done: full track |
| Add row | idle placeholder; editing (text field focused); hidden at 20 steps (`canAddStep`) |

## 5. Component mapping
| Design element | Maps to | Overrides / notes |
|----------------|---------|-------------------|
| Step Row | **new** `StepRow` | `isDone`, `text`; trailing grip |
| Add Step Row | `StepRow` layout, **no new view**: an `AddStepRow` variant or a `StepsField` row | plus replaces checkbox, text becomes an input |
| Suggest More Pill (125x28) and "Break it down" pill | **new** `SuggestPill(title:isLoading:)` | "Suggest more" and "Break it down" are the same pill with different titles |
| Progress Track + Fill | **new** `StepsProgressBar(progress:)` | takes `StepsProgress`, not raw numbers |
| Steps Field | **new** `StepsField` composing the above | used in Edit; Review (Phase 9) reuses it with the tag variant |
| Steps list card | same chrome as `FormFieldChrome` (surface, border, `DSRadius.md`) | do not duplicate the border constants |
| Task Row "2/5" | **already built**: `TaskRow` has `stepProgress: TaskRowStepProgress?` | only the list view must pass it; nothing new in the component |

## 6. Icons (Lucide → SF Symbol)
| Lucide | SF Symbol | Note |
|--------|-----------|------|
| `check` | `checkmark` | in table |
| `plus` | `plus` | in table |
| `sparkles` | `sparkles` | in table |
| `grip-vertical` | `line.3.horizontal` (proposal) | not in the phase-1 table; `line.3.horizontal` reads as a drag handle in iOS lists |
| `list-checks` | `checklist` (proposal) | row progress icon (15pt) |

## 7. Copy and accessibility
- "Steps", "N of M", "Suggest more", "Break it down", "Add a step". Phase 8 file says to use **"steps"** where the sheet button says "subtasks".
- Checkbox: button, label = step text, value "Done" / "Not done", action name "Mark as done" / "Mark as not done".
- Progress bar: one element, label "N of M steps done", not announced per change; the count text is hidden from VoiceOver to avoid duplication.
- Grip: not focusable; expose "Move up" / "Move down" accessibility actions on the row (phase decision D5).
- Pill loading: announce "Thinking of steps"; error text announced.
- Add row: label "Add a step", submit adds and keeps focus for the next step.

## 8. Suggested SwiftUI shape (names and parameters only)
- `StepRow(text: Binding<String>, isDone: Bool, onToggle: () -> Void, onSubmit: (String) -> Void)`
- `StepsProgressBar(progress: StepsProgress)`
- `SuggestPill(title: String, isLoading: Bool, action: () -> Void)`
- `StepsField(steps: [Step], progress: StepsProgress?, canAdd: Bool, showsProgress: Bool, onToggle: (StepID) -> Void, onRename: (StepID, String) -> Bool, onRemove: (StepID) -> Void, onMove: (Int, Int) -> Void, onAdd: (String) -> Bool, suggestion: SuggestPillState?)`
- Pure style structs as in `TaskRowStyle` (e.g. `StepRowStyle`) so colors, accessibility strings and the 44pt hit area are unit-testable.

## 9. Unknowns / questions
1. **Delete a step.** Not designed on the Edit screen. Decision D4 says swipe to delete; the existing `SwipeToDeleteRow` may be reusable inside a `List`. Confirm at build time.
2. **Reorder.** `List` + `onMove` with the grip as handle needs edit mode; if it does not fit, ship move up/down accessibility actions only (D5).
3. **Edit text inline.** Tap on the text edits in place (D4); no focused-state design exists. Proposal: reuse `FormControlBorder` focus style on the row.
4. **Progress bar at 0 and 100%.** Not designed; proposal above (empty and full track).
5. **Loading, error and offline states** for the pill and header: not designed (flag to the design).
6. **Row progress icon.** `jUq0s` is disabled in the master Task Row; the enabled variant appears on rows in the list frames. Confirm the "2/5" placement (Meta Row, after the category chip).
7. **Contradiction with the phase doc:** none. The only scope change is that `TaskRow` progress is already implemented (see section 5).
