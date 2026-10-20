---
name: phase-kickoff
description: Turn a phase file in docs/phases/ into confirmed decisions before any coding. Trigger when the user says to kick off, start, plan, or refine a phase (e.g. "kick off phase 2"), or when a phase file still has `open` decisions or an unfilled decision table. Writes no app code.
---

# Phase kickoff

Goal: every decision in the phase file is `confirmed` and written down, so implementation starts with a failing test. **Never write app code, tests, or production files in kickoff.** Only the phase file (and PLAN.md if scope changes) is edited.

## Procedure
1. **Read** `docs/phases/<phase>.md` and `docs/phases/PLAN.md`. Read `phase-0-foundation.md` and `phase-1-design-system.md` as the reference for the decision-table format and match it (groups A, B, C..., columns `#`, Decision, Options, Recommendation in bold, Status).
2. **Inspect the design** in `to-do.pen` through the `mcp__pencil__*` tools only (load them with ToolSearch if deferred; read the pencil skill/schema first). Never Read or Grep the `.pen` file: it is encrypted. Look at the frames and components this phase uses.
3. **Inspect the current repo state**: existing folders, Domain/Data/Presentation types, test target, what earlier phases actually delivered. Note drift from the plan.
4. **List the decisions** the phase needs, grouped (structure, domain, data, presentation, ...). Give each a recommendation and the trade-off in one line. Skip anything already decided in an earlier phase; reference it instead. Follow CLAUDE.md: Clean Architecture, value objects, YAGNI.
5. **Write the draft table** into the phase file with status `open`, and set the phase status line accordingly.
6. **Ask group by group** with `AskUserQuestion`: max 4 questions per call, recommended option first (labelled "(Recommended)"), options short, one decision per question.
7. **After each group's answers**, immediately update the phase file: status `**confirmed**` (add "(recommendation accepted)" or the user's choice). Do not batch the write-back to the end.
8. **Note design discoveries** that change scope (components that are really one with overrides, missing components, undesigned states, unmapped icons, assets needed). Record them in the phase file ("What the design actually contains") and update the Scope checklist; flag any change to PLAN.md to the user rather than silently editing it.
9. **Finish**: when all rows are confirmed, set the status to "all decisions confirmed, ready to start", make sure Scope, Out of scope, and Done when are current, and summarize in a few lines.

## Rules
- Xcode project-file edits (`.pbxproj`, new targets, build settings, bundling fonts or assets via the project, Info.plist registration) need explicit user permission. Flag every decision that implies one, in the table, and ask before implementation.
- Never install packages or add dependencies without explicit permission.
- If a decision is truly blocking, ask; otherwise state the assumption and proceed.
- Do not commit unless the user asks.
