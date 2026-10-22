# Phase 8: Steps (manual + Claude)

**Status:** built; open PR [#11](https://github.com/claramzfpp/to-do-list-ios/pull/11). Still to do: `design-fidelity-checker`, a full `accessibility-auditor` pass on the sheet and pill, and the doc-comment pass
**Design:** `to-do.pen`: "Edit Task – Steps" (`zZdaQ`), "Edit Task – Break it down" (`m52M44`), "Edit Task – Suggested Steps" (`f8WT4`), "Smart Add – Review" (`i1ysG`, Steps field), Task Row (steps progress)
**Depends on:** Phase 3 (`TodoItem`, SwiftData record, form), Phase 4 (Edit form, mode-based form view model), [Claude foundation](claude-foundation.md)
**Parallel with:** [Phase 9: Smart Add](phase-9-smart-add.md) (after the foundation is merged)

## Goal
Let a task have an ordered list of small steps the user can add, tick, reorder and delete, show progress ("2 of 5", a progress bar, "2/5" on the row), and let Claude suggest steps ("Break it down" and "Suggest more").

## What the design actually contains
**Edit Task – Steps (`zZdaQ`, 390x1233, scrolls)**
- A **Steps field** between Description and Category. Header row: label "Steps", DM Mono count "2 of 5", spacer, **"Suggest more"** pill (sparkle icon, 125x28, Outfit 13).
- A **progress track** (350x6) with a fill (140 of 350 = 2 of 5).
- A **Steps list** of 52pt rows: 24pt round **checkbox** (check icon when done), step text (Bricolage 16), a 16pt **grip icon** on the right (reorder handle). The last row is **"Add a step"** (plus in a 24pt circle, placeholder text).
- The Description label row has **no** "Break it down" pill here (it moved to the Steps header once steps exist). Delete task and Save changes below as in Phase 4.

**Edit Task – Break it down (`m52M44`)**: same Edit form with no steps yet. The Description label row has a **"Break it down"** pill (sparkle icon, 125x28). Tapping it asks Claude and opens the sheet below.

**Edit Task – Suggested Steps (`f8WT4`)**: a 390x495 bottom **Steps Sheet** over a 50% scrim: handle, 44pt sparkle badge, title "Suggested steps" (Fraunces), subtitle `For “<task title>”`, 5 rows (checkbox preselected for 4, one unselected; a pencil icon per row to edit the text), a full-width **"Add 4 subtasks"** button (the count follows the selection), and a **"Try different steps"** text button with a refresh icon.

**Smart Add – Review (`i1ysG`)**: a Steps field with tag "3 steps" (no progress bar, rows have checkbox, text and grip) and a "Suggest more" pill. Phase 9 reuses the same Steps field.

**Design discoveries**
- The Steps field and rows are **one component set** used in Edit, Add and Review: build once as design-system components (`StepRow`, `StepsProgressBar`, `StepsField`).
- Button copy says **"subtasks"** while the rest of the design says "steps". We use **"steps"** everywhere; flag to the design.
- **Not designed:** loading state while Claude answers, error and offline states, "no key" (entry points are hidden, see foundation C2), empty suggestion result, how a step is edited inline or deleted (swipe? the pencil icon exists only in the sheet), drag-reorder feedback, the Add form's Steps field before any step exists, the 'Suggest more' pill while loading, and whether the progress bar shows at 0 or 100%.
- The **Task Row** component is planned to show "2/5" (Phase 3 mentioned an optional steps progress; the row design shows it on the list).
- The Add Task form (Phase 3) is the variant **without** Steps. This phase adds the Steps field to **Edit** only; Add gains it through Phase 9 (Review). See B8.

## Decisions
Recommendation in **bold**. Group A answers are already given in the kickoff chat; the rest are `open` and will be confirmed group by group.

### A. Scope (already decided)
| # | Decision | Answer | Status |
|---|----------|--------|--------|
| A1 | Where the Claude steps live | **Phase 8 = manual steps + Claude steps** ("Break it down", "Suggest more", Suggested steps sheet) | **confirmed** (your choice) |
| A2 | Claude plumbing | Uses the shared [Claude foundation](claude-foundation.md); this phase adds only `StepSuggesting` and its Claude implementation | **confirmed** |

### B. Domain
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Shape | (1) `Step` entity (`StepID`, `StepTitle`, `isDone`) owned by `TodoItem`; (2) separate aggregate with its own repository | **(1) `Step` inside the `TodoItem` aggregate**; all changes go through `TodoItem` methods (`addStep`, `toggleStep`, `removeStep`, `moveStep`, `renameStep`), so invariants stay in one place. Amends Phase 0 C6 | **confirmed** (recommendation accepted) |
| B2 | `StepTitle` | trimmed, non-empty, max length | **Trimmed, non-empty, max 120 characters** (same as the task title); the field stops input at the limit | **confirmed** (recommendation accepted) |
| B3 | Limits | (1) none; (2) max steps per task | **Max 20 steps** (Claude cannot flood a task; the list stays usable). Adding beyond it throws `TodoItemError.tooManySteps` | **confirmed** (your choice: 20) |
| B4 | Progress | `StepsProgress` value (done, total, fraction) computed by `TodoItem` | **As described**, pure and tested (0 steps = no progress shown) | **confirmed** (recommendation accepted) |
| B5 | Task completion vs steps | (1) independent: ticking all steps does not complete the task and completing the task does not tick steps; (2) linked | **(1) Independent** (YAGNI, no surprising automation). Trade-off: the user ticks twice | **changed after build:** linked one way. Saving a task (Add or Edit) with at least one step and every step done completes it (`TodoItem.completeIfAllStepsDone`, called by `AddTodoItemUseCase` and `UpdateTodoItemUseCase`). It happens on Save, not when the last step is ticked, and un-ticking or adding a step never reopens the task. Completing the task still does not tick steps |
| B6 | Order | stable, user-controlled order; new steps append at the end | **As described**; `moveStep(from:to:)` | **confirmed** (recommendation accepted) |
| B7 | Use cases | `UpdateTodoItemUseCase` (Phase 4) already persists the whole item, so steps ride on it | **No new CRUD use cases.** Only `SuggestStepsUseCase` (B9). Trade-off: a step toggle in the list saves the whole item | **confirmed** (recommendation accepted) |
| B8 | Steps in the Add form | (1) Edit only in this phase; Add gets steps via Smart Add Review; (2) add the Steps field to Add too | **(1) Edit only.** Phase 3's Add has no Steps in the design; adding steps happens after creation. Trade-off: users cannot add steps while creating manually | **changed after build:** option (2). The Steps field, including the Claude pill, is in Add too, and its steps are saved with the new task (`AddTodoItemUseCase` takes `steps`). Deviation from the design, flag it |
| B9 | Suggestion port | `StepSuggesting` (Domain protocol): `suggest(title, description, existingSteps) async throws -> [StepTitle]`; `SuggestStepsUseCase` calls it | **As described.** Domain stays free of Claude. Result is 3 to 6 titles, validated (trim, drop empties and duplicates, cap at 20 total) | **confirmed** (recommendation accepted) |

### C. Data
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Persistence | (1) a Codable array on `TodoItemRecord` (new property with a default of empty); (2) `StepRecord` `@Model` with a relationship | **(1) Codable array** (`[StepDTO]`), atomic with the task and keeps order for free. SwiftData treats a new defaulted property as a lightweight change; verify with a test that opens an old-shape store. Trade-off: steps are not queryable | **confirmed** (recommendation accepted) |
| C2 | Mapper | `TodoItemMapper` maps `[StepDTO]` ⇄ `[Step]` with validation | **As described**, a corrupt title falls back to dropping that step (tested), never a crash | **confirmed** (recommendation accepted) |
| C3 | Claude implementation | `ClaudeStepSuggester` in Data: builds the request, forced tool `suggest_steps`, decodes a `StepSuggestionDTO`, maps to `[StepTitle]` | **As described**, prompt in one constant, tested with `FakeClaudeClient` | **confirmed** (recommendation accepted) |
| C4 | Prompt | system prompt: concise, imperative, 3 to 6 steps, same language as the task, no numbering; "suggest more" sends the existing steps and asks for new, non-overlapping ones | **As described** | **confirmed** (recommendation accepted) |

### D. Presentation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Form view model | extend the Phase 4 form view model with a steps draft and the suggestion state | **Extend it** (one form view model, mode-based), via a small `StepsEditor` helper to keep it focused. Shared file with Phase 9: see "Shared files" | **confirmed** (recommendation accepted) |
| D2 | Suggestion UI state | `idle / loading / suggestions([Selectable]) / failed(ClaudeError)` | **As described**; loading shows a spinner inside the pill and disables it (undesigned, flag) | **confirmed** (recommendation accepted) |
| D3 | Error display | undesigned | **Inline `danger` text under the Steps header** with "Try again"; offline gets its own copy. Flag to the design | **confirmed** (recommendation accepted) |
| D4 | Edit and delete a step | (1) tap the text to edit inline, swipe to delete; (2) the pencil/trash icons | **(1) Inline edit on tap, swipe to delete** (iOS idiom); the pencil in the sheet edits that suggestion before adding | **confirmed** (recommendation accepted) |
| D5 | Reorder | grip icon with `onMove` (edit mode) vs custom drag | **Native `List`/`onMove` with the grip as the handle** if it fits; otherwise move-up/down accessibility actions only. Decide at build time, covered by view-model tests either way | **confirmed** (recommendation accepted) |
| D6 | Sheet | `SuggestedStepsSheet` bottom sheet: selection, edit text, "Add N steps" (disabled at 0), "Try different steps" (re-asks) | **As described**; the count follows the selection | **confirmed** (recommendation accepted) |
| D7 | Task row progress | show "2/5" on `TaskRow` only when steps exist | **As described**; updates `TaskRow` (Phase 1) with an optional progress | **confirmed** (recommendation accepted) |
| D8 | Accessibility | checkbox = button with "done/not done" value; row label includes the step text; progress bar has a label "2 of 5 steps done"; loading and errors are announced; 44pt targets (the 24pt checkbox gets a larger hit area) | **As described**; run `accessibility-check` | **confirmed** (recommendation accepted) |
| D9 | Suggested steps when steps already exist | "Suggest more" excludes duplicates and respects the 20 limit | **As described** | **confirmed** (recommendation accepted) |

### E. Sequence and ownership
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| E1 | Internal order | **Domain (`Step`, `StepTitle`, `TodoItem` behaviors, `StepsProgress`) → persistence → manual Steps UI in Edit + row progress → Claude suggestion (port, use case, Claude implementation) → sheet** | **confirmed** (recommendation accepted) |
| E2 | Shared files with Phase 9 | `TodoItemFormViewModel` (steps draft), the Steps field components, composition root. **Phase 8 owns the Steps components and `StepsDraft`; Phase 9 only consumes them.** Phase 9's Review screen is wired after Phase 8's field exists, or uses a minimal stub of it | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [x] `StepID`, `StepTitle`, `Step`, `StepsProgress`; `TodoItem` step behaviors; `TodoItemError` cases; tests first
- [x] Persistence of steps (defaulted property), mapper, old-shape store test
- [x] DS components: `StepRow`, `StepsProgressBar`, `StepsField`, `SuggestPill`; `TaskRow` progress
- [x] Form view model: steps draft (add, toggle, edit, delete, move, limit)
- [x] `StepSuggesting`, `SuggestStepsUseCase`, `ClaudeStepSuggester`, `FakeStepSuggester` (the fake lives in the test target)
- [x] "Break it down" and "Suggest more" pills; `SuggestedStepsSheet`. Both pills are one pill in the Steps header (its title follows whether steps exist), not in the Description row as designed. Flag to the design
- [x] Previews per state; `accessibility-check` (Steps components)
- [ ] `accessibility-auditor` pass on `SuggestedStepsSheet` and the pill states; `design-fidelity-checker`; doc-comment pass in its own commit
- Not unit tested (previews only): the views in `TodoItemFormView` and `SuggestedStepsSheet`; the logic behind them is covered through the view model

## Out of scope
- Smart Add (Phase 9), the Claude client itself (foundation), nested steps, step due dates, templates
- Steps in the manual Add form (B8), drag between tasks, step notes

## Done when
- A task can get steps in Edit: add, tick, rename, delete, reorder; they survive a relaunch and the row shows "N/M".
- With a key, "Break it down" opens the sheet with selectable steps and adds the chosen ones; "Suggest more" adds non-duplicate steps; failures show an error with "Try again".
- Without a key, no Claude entry point appears; manual steps still work.
- Domain stays free of Claude and SwiftData; the design-fidelity check shows no High differences.
