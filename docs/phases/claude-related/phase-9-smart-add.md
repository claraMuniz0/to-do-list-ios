# Phase 9: Smart Add

**Status:** all decisions confirmed, ready to start
**Design:** `to-do.pen`: "Smart Add – Describe" (`S6F0TQ`), "Smart Add – Review" (`i1ysG`); entry point: the "Manual"/Smart add button in the Add Task nav (`P8zacl`)
**Depends on:** Phase 3 (Add form, `AddTodoItemUseCase`, categories), Phase 7 (custom categories, "+ New"), [Claude foundation](claude-foundation.md); Steps field from [Phase 8](phase-8-steps.md)
**Parallel with:** Phase 8 (after the foundation is merged)

## Goal
Let the user describe a task in one sentence ("Dentist next Tuesday at 3pm, high priority. Bring insurance card."), have Claude fill the task form, and review and save it.

## What the design actually contains
**Smart Add – Describe (390x844)**
- Nav: Close (44pt circle) on the left, a **"Manual"** pill (pencil icon) on the right that returns to the manual Add form.
- Header: Caveat "Just say it", Fraunces "Smart *add*" (accent word).
- **Smart Input** card (350x190, focused style): sparkle icon + label "Describe your task", the typed text (Bricolage 20), counter **"66 / 280"** (DM Mono), and a 36pt **mic button**.
- **Examples:** label "Or try something like" and three pills (arrow icon): "Buy milk tomorrow morning", "Team sync Friday 10am, work", "Mom's gift by next week". Tapping one presumably fills the input.
- Privacy note: shield icon, "Claude fills the form. You review before saving."
- Primary button **"Fill it in"** (sparkle icon).

**Smart Add – Review (390x1111, scrolls)**
- Nav: only Close. Header: Caveat "Here's what I understood", Fraunces "Looks *right?*".
- **AI Banner** (sparkle, "Filled in by Claude. Tap any field to adjust.").
- The Add form prefilled: Task name, Description ("Bring insurance card"), **Steps** field ("3 steps", rows with checkbox/grip, "Add a step", "Suggest more" pill), Category chips (Personal selected, "+ New"), Due date **"Tue, Oct 13 · 3:00 PM"**.
- Button **"Save task"**.

**Design discoveries**
- The Review screen is the **Add form plus a banner and a Steps field**: reuse the form view model and components; do not build a second form.
- The example sentence has **"high priority"** and the date shows a **time**; the app has neither (kickoff decision: **date only, priority ignored**; flag to the design). Claude is told to drop priority and time; they may be kept in the description.
- The **mic button** needs speech recognition (Info.plist usage strings and a capability, a project-file edit). Not built (see C4).
- **Not designed:** the loading state after "Fill it in", errors (offline, rate limit, bad answer), "no key" (entry hidden), a sentence Claude cannot understand, over-280 input, empty input (button state), keyboard behavior on the Describe screen, which fields Claude left empty, the Add screen's button label ("Manual" is shown only on Describe).
- Review's Close discards everything (as Phase 3 A6). Back to Describe is not designed.
- The privacy line must be **honest**: the typed text is sent to Claude. The designed copy says Claude fills the form but not that data leaves the device; flag a copy change.

## Decisions
Recommendation in **bold**. Group A answers are already given in the kickoff chat; the rest are `open`.

### A. Scope (already decided)
| # | Decision | Answer | Status |
|---|----------|--------|--------|
| A1 | Due time and priority | **Date only, priority ignored** | **confirmed** (recommendation accepted) |
| A2 | Claude plumbing | Uses the shared [Claude foundation](claude-foundation.md) | **confirmed** |

### B. Domain
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | Result type | `TaskDraft` value in Domain: title (`TodoItemTitle`), description?, `CategoryID`, `DueDate?`, `[StepTitle]` | **As described.** A draft is already valid domain data; it is not saved until the user taps Save | **confirmed** (recommendation accepted) |
| B2 | Port | `TaskDraftParsing` (Domain protocol): `parse(_ text: SmartAddText, context) async throws -> TaskDraft`; `context` = today (`DateProvider`), the category list | **As described**; `ParseTaskDraftUseCase` calls it | **confirmed** (recommendation accepted) |
| B3 | `SmartAddText` value object | trimmed, non-empty, max 280 characters | **As described** (matches the 280 counter); the field stops input at 280 | **confirmed** (recommendation accepted) |
| B4 | Relative dates | Claude receives today's date (year-month-day) and resolves "next Tuesday", "tomorrow", "Friday" | **Claude resolves**; Data parses `YYYY-MM-DD` into `DueDate`; an invalid or past-by-years date becomes `nil`. "Next week" follows Phase 3 B6 (today + 7) and is stated in the prompt | **confirmed** (recommendation accepted) |
| B5 | Category mapping | Claude picks one of the **current categories by id** (built-ins and custom, from Phase 7); unknown or missing → Personal (Phase 7 B4 rule) | **As described** | **confirmed** (recommendation accepted) |
| B6 | What Claude must not invent | title is required; description, date and steps are optional and left empty when not in the sentence | **As described**; no hallucinated steps (steps only if the user listed them) | **confirmed** (recommendation accepted) |
| B7 | Failure when nothing useful | an unusable answer (no title) → `SmartAddError.couldNotUnderstand` with a message and the text kept | **As described** | **confirmed** (recommendation accepted) |

### C. Data
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Implementation | `ClaudeTaskDraftParser` in Data: forced tool `create_task_draft` with a JSON schema, decoded into `TaskDraftDTO`, mapped (validated) into `TaskDraft` | **As described**; tested with `FakeClaudeClient` for success, partial, malformed, empty title, bad date, unknown category | **confirmed** (recommendation accepted) |
| C2 | Prompt | system prompt in one constant: role, the allowed category ids, today's date, "date only, no times", "ignore priority", "answer in the language of the sentence", "do not invent" | **As described** | **confirmed** (recommendation accepted) |
| C3 | Untrusted output | validate every field again in Data; never trust lengths or ids | **As described**; the user also reviews before saving | **confirmed** (recommendation accepted) |
| C4 | Mic / dictation | (1) not built; the keyboard's own dictation key works in the text field; (2) `Speech` framework | **(1) Not built.** Speech needs Info.plist and capability edits (project file) and the privacy surface grows. The mic button is **not shown** (no dead button, Phase 3 D4) | **confirmed** (your choice: not built) |

### D. Presentation
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| D1 | Navigation | Add Task nav gets a **Smart add** button (the design shows it); Describe → Review is inside the same full-screen cover; "Manual" returns to the Add form | **As described**, router-driven like Phase 3 A1; the button appears only when Claude is available (foundation C2) | **confirmed** (recommendation accepted) |
| D2 | View models | `SmartAddViewModel` (input, examples, counter, state `idle / loading / failed`) tested first; Review reuses the Phase 4 mode-based form view model with a new mode `.reviewingDraft(TaskDraft)` | **As described** | **confirmed** (recommendation accepted) |
| D3 | "Fill it in" | disabled when the input is empty; loading state replaces the label with a spinner and disables input (undesigned, flag); cancels the request on Close | **As described** | **confirmed** (recommendation accepted) |
| D4 | Example pills | tapping fills the input (replaces the text) | **As described** (assumed, behavior not specified) | **confirmed** (recommendation accepted) |
| D5 | Error display | inline `danger` text under the input with "Try again" or an explanation; text is kept | **As described**; flag to the design | **confirmed** (recommendation accepted) |
| D6 | Review banner | shown only in the Review mode; hidden once the user edits a field? | **Always shown on Review** (simple); flag | **confirmed** (recommendation accepted) |
| D7 | Save | Review's Save uses `AddTodoItemUseCase` with the draft's values and steps (steps persisted via Phase 8; until then, steps are dropped and flagged) | **As described**; coordinate with Phase 8, see E2 | **confirmed** (recommendation accepted) |
| D8 | Accessibility | the input has a label and a character-count value; examples are buttons; the loading state and errors are announced; the sparkle icons are decorative; run `accessibility-check` | **As described** | **confirmed** (recommendation accepted) |
| D9 | Privacy note copy | designed text vs an honest line | **Use: "Claude fills the form. Your text is sent to Claude. You review before saving."** Flag to the design | **confirmed** (your choice: honest line) |

### E. Sequence and ownership
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| E1 | Internal order | **Domain (`SmartAddText`, `TaskDraft`, port, use case) → Data (parser) → `SmartAddViewModel` → Describe screen → Review mode + banner → Add nav entry** | **confirmed** (recommendation accepted) |
| E2 | Shared files with Phase 8 | the form view model and the Steps field. **Phase 9 does not build Steps UI.** If Phase 8's Steps field is not merged when Review is built, the draft's steps are kept in the `TaskDraft` and Review shows the banner and fields without the Steps field; the field is added at merge | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] `SmartAddText`, `TaskDraft`, `TaskDraftParsing`, `ParseTaskDraftUseCase`, `SmartAddError`; tests first
- [ ] `ClaudeTaskDraftParser` (schema, prompt, DTO mapping and validation), `FakeTaskDraftParser`
- [ ] `SmartAddViewModel`; the Describe screen (input, counter, examples, privacy note, "Fill it in")
- [ ] Review mode in the form view model, banner, Save through `AddTodoItemUseCase`
- [ ] Smart add entry in the Add Task nav (hidden without a key)
- [ ] Previews per state; `accessibility-check`; `design-fidelity-checker`; doc-comment pass in its own commit

## Out of scope
- The Claude client and key (foundation), the Steps UI (Phase 8), mic/dictation, due time, priority, multi-task input ("buy milk and call mom"), saving without review

## Done when
- With a key, typing a sentence and tapping "Fill it in" opens Review with title, description, category and date filled; the user can edit and Save, and the task appears in the list.
- Failures keep the typed text and show an error with "Try again"; without a key the entry point does not appear.
- Parsing rules (relative dates, unknown category, empty title, over-length) are covered by tests with no network access.
