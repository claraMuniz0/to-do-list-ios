# Planning the Claude-powered features: process log

A record of how Phases 8 (Steps) and 9 (Smart Add), plus a shared Claude foundation, were planned with Claude Code on top of the already-planned to-do app. Companion to [ai-assisted-planning-log.md](ai-assisted-planning-log.md). It covers what we did, what went wrong, and what I would repeat.

## 1. Context
- **App:** the iOS to-do app, still **plan-only**: Phases 0 to 7 are documented and confirmed, with no Swift beyond the Xcode template.
- **Request:** create two separate phases, "manual sub-steps on a task" and "Smart Add", both using Claude and an API key; read the Pencil design for the UI; use the `phase-kickoff` skill; delegate the build to two agents.
- **Constraints:** global `CLAUDE.md` (Clean Architecture, TDD, no package installs or project-file edits without permission, never read secrets).
- **Result:** three new docs with every decision confirmed ([claude-foundation.md](../phases/claude-foundation.md), [phase-8-steps.md](../phases/phase-8-steps.md), [phase-9-smart-add.md](../phases/phase-9-smart-add.md)), `PLAN.md` and the backlog updated, **no agents launched** (see 5.3), and a new `process-log` skill.

## 2. Timeline

| Step | What happened | Claude features used |
|---|---|---|
| 1. Load the kickoff skill | Invoked `phase-kickoff` with the two phase ideas. | `Skill` |
| 2. Read the plan and repo | Read `PLAN.md`, the backlog and Phase 7 (as the format reference); listed tracked files. | Bash, Read |
| 3. Find the design | Pencil's app state listed the open `.pen` file; top-level frames included Smart Add (Describe, Review) and Edit Task (Break it down, Suggested Steps, Steps), which the plan had only called "post-MVP". | Pencil MCP, `get_app_state`, `execute` |
| 4. Read five frames | Printed each frame's tree (names, text, icons, sizes) and took screenshots to check layout. | Pencil `execute` (`Get`/`Print`/`TakeScreenshot`) |
| 5. Draft three files | Wrote the foundation, Phase 8 and Phase 9 tables with recommendations and design discoveries. | File writes |
| 6. Scope questions (round 1) | Four blocking questions: where Claude steps go, how the key is supplied, how two agents share one client, due time and priority. | `AskUserQuestion` |
| 7. Detail questions (rounds 2 and 3) | Model, missing-key behavior, step storage, steps in Add, mic, completion link, privacy copy, step limit, then "accept the rest" and project-file permission. | `AskUserQuestion` |
| 8. Write back | Marked rows confirmed with the user's choices, updated `PLAN.md` and the backlog. | Python edit script, grep |
| 9. Reality check | Checked branches and Swift files: nothing from Phases 0 to 7 is built, so the build agents could not start. Reported it and offered two paths. | Git, grep |
| 10. Architecture question | The user asked about calling Claude from Python. Explained that Python cannot run in an iOS app and compared direct calls with a Python backend. The user chose direct calls for now ("I just want to test"). | Conversation |
| 11. This log and its skill | Created the `process-log` skill and this document. | File writes |

## 3. The working method

### 3.1 Design read as data
As before, the design was queried, not eyeballed. Reading the frames' trees found:
- The **Steps field** is one set of parts used in three screens (Edit, Review, and the sheet's rows), so Phase 8 builds it once.
- The Smart Add Review is the **Add form plus a banner and a Steps field**, so Phase 9 reuses the form view model instead of building a second form.
- The **Review shows a due time and the example says "high priority"**, which the domain (date only, no priority) cannot hold.
- The **mic button** implies speech recognition (permissions and a project-file edit).
- The design copy says "subtasks" in one place and "steps" everywhere else, and its privacy line does not say the text leaves the device.

### 3.2 Decisions
Same decision-table format as Phases 0 to 7. New in this round: a **"Shared files" row** in each parallel phase naming who owns what (Phase 8 owns the Steps components, Phase 9 only consumes them), because two agents will edit the same area.

### 3.3 Separating the shared piece
Both features need a Claude client. Instead of letting each phase build one, it became its own small prerequisite (the foundation), built first by one agent, so the two phase agents can run in parallel on disjoint files.

### 3.4 Asking the human
Three rounds, at most four questions each, recommended option first. The first round was the real scope choices; the later rounds were smaller, and a final "accept all remaining recommendations" question closed the table without asking about every row.

## 4. Skills and tools

| Item | Purpose |
|---|---|
| `phase-kickoff` (existing) | Drove the whole session. |
| `process-log` (new) | Writes a process log like this one in `docs/process/`. |
| Pencil MCP | Read the design frames. |
| `AskUserQuestion` | Grouped decisions. |

No new agents. The planned build delegation (see 5.3) would use `component-builder` for the screens and the TDD skills for Domain and Data.

## 5. What went well, and what went wrong

### 5.1 Went well
- The design already contained both flows; reading it as data turned "post-MVP backlog" bullets into precise scope in a few calls.
- Splitting out the foundation removed the main parallel-work conflict before it existed.
- The user's answers were recorded in the files the moment they were given.
- Secrets handling: a Python test folder with a `.env` was in scope; only the script was read, with any key-looking string redacted, and the `.env` was never opened.

### 5.2 Problems found by planning
1. **Design vs domain:** time and priority in Smart Add have nowhere to live; settled as date-only.
2. **Key in the binary:** a config-file key ships with the app, so it is flagged as development-only, and the project-file edit it needs was put behind explicit permission.
3. **Honesty of copy:** the privacy line was rewritten to say the text is sent to Claude.
4. **Undesigned states:** loading, errors, offline, no key, step edit/delete, reorder feedback are all unknown to the design and listed for the designer.

### 5.3 Friction and corrections
- **The build could not start.** The request assumed an app to build on, but Phases 0 to 7 are plans only. I found this **after** writing the three phase files, by checking the repo as the last step. It should have been checked first; the docs were still valid, but the "delegate to two agents" part was premature and I did not launch them.
- **The Python question came late.** The user expected API calls in Python; I had put the Swift-direct approach in the foundation (and asked about the key, but not about the architecture). Python cannot run inside an iOS app, so the real alternative is a Python backend. A question such as "where does the Claude call run: in the app or on a server?" belonged in the first round.
- **A bulk edit script half-failed.** Replacing every `open` status ran before targeted edits whose search strings still contained `open`, and one search string did not match the file's wording. The error was visible and a follow-up grep confirmed zero `open` rows remain after fixing it.
- **Interactive skill, non-interactive agents** still applies: the build agents would not be able to ask questions, so the permission for the project-file edit was collected up front.

## 6. Numbers
- 3 phase documents created, `PLAN.md` and the backlog edited.
- Counted decision rows: about 70 across the three files (not audited line by line).
- 4 `AskUserQuestion` rounds, about 14 questions, plus one explanation turn.
- 5 Pencil frames read, plus screenshots.
- 0 lines of Swift; 0 agents launched; 0 commits (none requested yet).
- Time and tokens: not tracked.

## 7. Suggested article angle
- "Planning an AI feature before there is an app: what a design file tells you for free."
- "The shared-foundation trick for parallel agents: pull the common client out before you fork the work."
- "Check what exists before you plan to build on it" as a short cautionary section (5.3).

## 8. What I would do differently
- Check the repo's real state (what is built) **before** drafting or promising delegation.
- Ask "where does the model call run: app or backend?" in the very first question round.
- Put the process-log skill in place at the start of a series of sessions so each one is logged as it happens, not afterwards.
- Verify bulk-edit scripts with a grep immediately (this time the output made the failure obvious, but only after the next step).

## 9. Reproducing this
1. Open the design in Pencil and confirm the MCP server reads it.
2. Run `phase-kickoff` for each new phase; read the relevant frames as data.
3. Extract anything two phases share into its own prerequisite file.
4. Ask in groups of at most four, recommended option first; write answers back immediately.
5. Before delegating builds, check the dependencies are actually built.
6. Record the session with the `process-log` skill.

## 10. Where things are
- New phases: [claude-foundation.md](../phases/claude-foundation.md), [phase-8-steps.md](../phases/phase-8-steps.md), [phase-9-smart-add.md](../phases/phase-9-smart-add.md); index in [PLAN.md](../phases/PLAN.md)
- New skill: `.claude/skills/process-log/SKILL.md`
- Earlier log: [ai-assisted-planning-log.md](ai-assisted-planning-log.md)
- Design: `to-do.pen` (Pencil)
