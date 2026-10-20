# Planning an iOS app with Claude Code: process log

A record of how the to-do app was planned with Claude Code **before writing any Swift**, written for later review and as raw material for an article. It covers what we did, in what order, which Claude features did the work, what went wrong, and what I would repeat.

## 1. Context
- **App:** a to-do list for iOS (SwiftUI, SwiftData), designed in Pencil (`to-do.pen`, 18 screens + component library).
- **Constraints, set in the global `CLAUDE.md`:** Clean Architecture, strict TDD, small atomic commits with Conventional Commits, no package installs or Xcode project-file edits without explicit permission.
- **Decision for this session:** build **no code**. Plan every phase first, with an MVP mindset.
- **Result:** 8 phases (0 to 7) with every decision confirmed, 12 project skills, 5 project agents, and a plan that is traceable to the design.

## 2. Timeline

| Step | What happened | Claude features used |
|---|---|---|
| 1. Check access | Asked whether Claude could reach the Pencil app and the open `.pen` file. | MCP server (Pencil), `get_app_state` |
| 2. Scan the design | Read all screens and design tokens (colors, fonts, radii, components) through scripts, not screenshots. | Pencil `execute` (`Get`/`Print` visitors) |
| 3. Macro plan | Turned the screens into phases: design system, welcome/empty, add task, edit task, plus a foundation phase and a post-MVP backlog. Filters were moved out of the MVP. | Plain conversation, `AskUserQuestion` |
| 4. One file per phase | `PLAN.md` plus `docs/phases/phase-N-*.md`, each with goal, scope checklist, out of scope, done-when. | File writes |
| 5. Phase 0 decision tables | Inspected the repo (found: one target, no test target, placeholder bundle ID, iPad/Vision enabled) and listed decisions with a recommendation each. | Repo inspection, `AskUserQuestion` in groups |
| 6. Phase 1 decisions | Read the component library and discovered that many "components" are one component with overrides. | Pencil scripts |
| 7. Skills and agents | Brainstormed, then delegated to **five parallel subagents** that created 7 skills and 4 agents. | `Agent` tool (background), `.claude/skills`, `.claude/agents` |
| 8. Reuse from another project | Reviewed a previous project's `.claude/` folder and ported the useful parts, adapted to this app's decisions. | Reading another repo's skills/agents |
| 9. Rename | Found a naming collision (`Task`) and renamed the entity everywhere. | Grep + scripted replace |
| 10. Phases 2 to 4 | Ran the new `phase-kickoff` skill phase by phase, group by group. | Skill, `AskUserQuestion`, Pencil |
| 11. Phases 5 to 7 | Delegated the drafts to **three parallel subagents** running the same skill, then settled the decisions with me in groups. | Skill, background agents |
| 12. Commits | Docs and tooling committed separately (`docs:` vs `chore:`). | Git via Bash |

## 3. The working method

### 3.1 Design as the source of truth, read programmatically
Claude never "looked at" screenshots to plan. It queried the `.pen` file through the Pencil MCP tools and printed compact rows (node names, text, icon names, fills, references). That is how it found things a quick look would miss:
- Save Button, Add First Task Button, Category Option and Today Pill are **instances of base components** with overrides, so the plan has one `PrimaryButton`, one `CategoryChip`, one `FilterPill`.
- The Welcome "illustration" is a **composed set of shapes**, not an icon. A first, quick read said icon; a second read corrected it, and the plan was fixed.
- The list row never shows a due date; the Categories frame contradicts its own counts; the toast uses a font outside the design system; the Sort button has no menu designed.

### 3.2 The decision table
Every phase file has a table: `# | Decision | Options | Recommendation (bold) | Status`. Status moves `open` to `confirmed` (or `assumed` for small, non-blocking items, or `deferred`). Rules we followed:
- One recommendation per decision, with the trade-off in one line.
- Never re-litigate an earlier confirmed decision; reference it.
- Write the answer back into the file **immediately** after each group of questions, not at the end.
- Small things become `assumed` and are stated, not asked.

### 3.3 Asking the human well
`AskUserQuestion` in groups of at most four, recommended option first, short options, one decision per question. The user could accept a recommendation or type a different answer (twice they changed scope, see 5.1).

### 3.4 Knock-on edits
A decision in one phase often changed another. Examples we applied explicitly:
- Phase 3 needs `createdAt` and a `DateProvider` (amends Phase 0).
- The Close button on Add Task means a modal presentation (amends Phase 2's navigation).
- Custom categories in Phase 7 forced Phase 3 to store a plain `categoryID` now, to avoid a migration later.
Each impact is listed in an "Impact on earlier phases" section, then applied only after the user confirmed the decision.

## 4. Skills and agents we created

### Skills (`.claude/skills/<name>/SKILL.md`)
| Skill | Purpose |
|---|---|
| `phase-kickoff` | Turn a phase file into confirmed decisions (read, inspect design and repo, draft table, ask in groups, write back). Never writes code. |
| `tdd-cycle` | One red, green, refactor loop; commit messages per phase; "never rerun a failing test more than 3 times". |
| `new-value-object` | Self-validating value object, test first. |
| `new-use-case` | Domain use case with a hand-written repository double. |
| `new-ds-component` | One design-system SwiftUI component (tokens, previews, gallery entry). |
| `new-screen` | Feature screen with an `@Observable` view model. |
| `create-preview` | One preview per state with deterministic `#if DEBUG` sample data. |
| `accessibility-check` | Fix-as-you-build accessibility checklist. |
| `define-location` | Which layer does this belong in? |
| `naming-convention` | Names per layer and for tests and fixtures. |
| `design-to-swiftui-spec` | Read the `.pen` file and write a spec, not code. |
| `doc-comments-pass` | The "WHY, not WHAT" doc pass, in its own commit. |

### Agents (`.claude/agents/<name>.md`)
| Agent | Role | Tools |
|---|---|---|
| `clean-architecture-reviewer` | Read-only check of layer boundaries | Read, Grep, Glob, Bash |
| `test-quality-reviewer` | Read-only check of TDD discipline and coverage | Read, Grep, Glob, Bash |
| `design-fidelity-checker` | Compare the running app to the design | Pencil + simulator tools |
| `accessibility-auditor` | Read-only audit with measured contrast | Read, Grep, Glob, simulator |
| `component-builder` | Build one Presentation piece end to end | Edit/Write + Pencil |

Design choices worth noting: reviewers are **read-only** and separate from the builder; skills hold procedures, `CLAUDE.md` holds rules, agents isolate heavy work.

## 5. What went well, and what went wrong

### 5.1 Went well
- **Parallel subagents with non-overlapping files.** Five agents wrote 11 files at once; later three agents drafted Phases 5 to 7. Each brief named the one file it could edit.
- **The user steering mid-process:** "swipe delete should be its own phase" created Phase 5; "should phase 7 have a kickoff too?" surfaced the category migration risk early.
- **Reusing another project's skills** (naming, preview, component, accessibility, documentation) saved time and exposed gaps in ours.
- **Catching problems before code exists** (section 5.2).

### 5.2 Problems found by planning (each would have cost real time later)
1. **`Task` collides with Swift concurrency's `Task`.** The entity was renamed `TodoItem` before any code existed. Found by comparing with a previous project's note about shadowing `Character`.
2. **`Clock` already exists in Swift**, so the injectable clock became `DateProvider`.
3. **Add Task has a Close (X) button**, so it is a modal cover, not a pushed screen.
4. **Custom categories would force a migration** if Phase 3 stored a fixed set; settled before Phase 3 by storing a plain id.
5. **Two color pairs fail contrast** (Ochre 3.2, Teal 4.2 against 4.5), and the swatches are 40pt against a 44pt target.
6. **Design inconsistencies:** Edit mock selects the wrong category, Categories counts contradict the list, toast font outside the design system.

### 5.3 Friction and corrections
- **Subagents cannot ask the user questions.** The kickoff skill is interactive, so the agents drafted tables and left decisions `open`; the main session then asked the user. Worth stating in an article: design the skill so the interactive step can be separated.
- **Agent reports are claims, not facts.** One agent said `PLAN.md` was at a different path than the one I had written; I checked, and the user had moved it. Each handback was verified against the files before relaying it.
- **A relative-link bug:** moving `PLAN.md` into `docs/phases/` broke its links; fixed on the next edit.
- **A mistake in a reply:** a first summary of the Welcome illustration said "an icon in a frame"; the later, deeper read corrected it and Phase 1 was updated.
- **Over-eager scripting:** a shell variable with several filenames did not split in zsh, so a replace failed silently the first time; the follow-up grep caught it.
- **Scope drift handled by the user:** I proposed Phase 6 as search and sort; the user asked for a Phase 7 kickoff after I explained the category dependency.

## 6. Numbers
- 8 phase files, 1 plan, 1 backlog; about 150 confirmed or assumed decisions.
- 12 skills, 5 agents (11 created by 5 parallel agents; 6 by hand or ported).
- 12 commits, in separate `docs:` and `chore:` commits.
- 0 lines of Swift.

## 7. Suggested article angle
Working title ideas:
- "I planned a whole iOS app with Claude Code before writing a line of Swift"
- "Decision tables, skills and subagents: a planning workflow for AI-assisted development"

Possible structure:
1. Why plan first (the cost of discovering a naming collision after 40 files).
2. Design as data: letting the AI read the design file, not screenshots.
3. The decision table pattern, with a real excerpt.
4. Turning repeated procedures into skills; keeping rules in `CLAUDE.md`.
5. Subagents: what to parallelize (disjoint files), what not to (anything interactive).
6. Verification habits: check agent claims, grep after scripted edits.
7. Findings list (section 5.2) as the payoff.
8. What I would do differently (section 8).

## 8. What I would do differently
- Write the `phase-kickoff` skill **first**, so Phases 0 and 1 used it too.
- Capture design screenshots of the final states per phase for the article.
- Record token and time cost per step (not tracked here).
- Define the file layout and link style up front (the `PLAN.md` move caused an avoidable fix).

## 9. Reproducing this
1. Open the design in Pencil; confirm the MCP server can read it.
2. Write global rules in `CLAUDE.md` (architecture, TDD, safety).
3. Draft macro phases; one markdown file each; decision tables as above.
4. Create `phase-kickoff`, then run it per phase.
5. Create procedure skills and read-only reviewer agents once the first phase exposes repeated steps.
6. Delegate drafts to parallel agents with one-file briefs; confirm decisions with the user afterwards.
7. Commit docs and tooling separately.

## 10. Where things are
- Plan and phases: `docs/phases/` (`PLAN.md`, `phase-0` to `phase-7`, `backlog-post-mvp.md`)
- Skills: `.claude/skills/`
- Agents: `.claude/agents/`
- Design: `to-do.pen` (Pencil)
