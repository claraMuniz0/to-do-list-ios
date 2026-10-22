# From idea to pull request: the phase workflow

A description of how one new phase is taken from a rough idea to an open pull request in this repo, using Claude Code with the project's skills and agents. Written as reference and raw material for an article. Companion to [ai-assisted-planning-log.md](ai-assisted-planning-log.md) (how the plan was made) and [claude-features-phases-process-log.md](claude-features-phases-process-log.md) (how the Claude-powered phases were planned).

This document describes the intended workflow. It is a method, not a log of one session.

## 1. The shape of the workflow

```
idea -> phase file -> kickoff (decisions) -> branch -> TDD loops -> independent reviews -> docs pass -> PR
```

Two principles run through every step:

- **Docs first, code second.** No production code exists until every decision in the phase file is `confirmed`.
- **Small, verifiable steps.** One behavior per TDD loop, one commit per phase of the loop, and a human checkpoint wherever a decision is really theirs to make.

## 2. Step by step

### 2.1 Idea to phase file
- The idea starts as one or two sentences from the human.
- If the design already contains the feature, Claude reads the relevant frames in pen.dev through the Pencil MCP tools. This is where a vague idea becomes precise scope: sizes, copy, states and components that exist (and the ones that are missing).
- A new file `docs/phases/phase-N-name.md` is created with: status, which design frames it uses, dependencies on earlier phases, goal, scope, out of scope, and a "done when" criterion.
- `docs/phases/PLAN.md` gets the new phase and a link to its file.

### 2.2 Kickoff (skill: `phase-kickoff`)
The kickoff writes **no app code**. Its only output is a phase file in which every decision is confirmed.

1. **Read** the phase file, `PLAN.md`, and earlier phase files as the reference for the decision-table format.
2. **Inspect the design** through the Pencil tools only. The `.pen` file is encrypted and is never read directly.
3. **Inspect the real repo state:** existing folders, domain types, the test target, and what earlier phases actually delivered. Note any drift from the plan.
4. **Draft the decisions**, grouped (structure, domain, data, presentation). Each row has the options, a recommendation in bold, a one-line trade-off, and status `open`. Anything already decided in an earlier phase is referenced, not re-asked.
5. **Ask group by group** with `AskUserQuestion`: at most four questions per call, the recommended option first, one decision per question.
6. **Write back after every group.** Rows flip to `confirmed` (with "recommendation accepted" or the human's own choice) immediately, not at the end.
7. **Record design discoveries** that change scope: states that were never designed, components that are really one with overrides, inconsistent copy, assets needed, and anything that implies an Xcode project-file edit.
8. **Finish** when every row is confirmed: status "all decisions confirmed, ready to start", with scope, out of scope and done-when up to date.

Lessons from earlier phases:
- Check the repo's real state **before** drafting or promising delegation.
- Ask the architectural question first. For example: "where does the Claude call run, in the app or on a server?" belongs in the first round, not the last.
- Collect every permission that agents will need (project-file edits, new dependencies) up front, because background agents cannot ask questions.

### 2.3 Preparation
- Create a branch `feat-phase-N-short-name` from `main`.
- If two phases will run in parallel, **pull out what they share** into a small prerequisite phase and build it first (the Claude foundation did this for Steps and Smart Add). Each parallel phase also gets a "shared files" row saying who owns what.
- Resolve pending permissions now (see above).

### 2.4 Implementation (skill: `tdd-cycle`)
Work proceeds one behavior at a time. Supporting skills decide where code goes and how it is named: `define-location` (which Clean Architecture layer) and `naming-convention`.

Each loop:

| Phase | What happens | Commit |
|-------|--------------|--------|
| Red | Write one failing test, in a test folder that mirrors production. Run it and confirm it fails for the right reason. | `test: add failing test for <feature>` |
| Green | Write the minimum production code to pass. Run the relevant suite. | `feat: implement <feature> to pass test` |
| Refactor | Clean up production and test code while green, one layer at a time. | `refactor: clean up <target> without altering behavior` |

Typical order inside a phase:
1. Value objects and entities in Domain (`new-value-object`).
2. Use cases against a hand-written repository test double (`new-use-case`).
3. Data layer: DTOs, mappers and repository implementations.
4. Presentation: design-system components (`new-ds-component`), screens wired to `@Observable` view models (`new-screen`), previews (`create-preview`), and a fix-as-you-build accessibility pass (`accessibility-check`). The `component-builder` agent can build one component or screen end to end.

Guardrails that keep the loop honest:
- Never rerun the same failing test command more than three times without changing code. Stop and analyze.
- Run only the relevant suite, in the background, capped at about 30 seconds. Never run the full suite without the human's OK.
- Cover boundaries, empty states and failure paths. Never swallow errors.
- No package installs and no Xcode project-file edits without explicit permission. Never read or commit secrets.

### 2.5 Independent reviews
When the feature is green, read-only agents give a second opinion that is not anchored on the builder's view. They report findings and never edit files.

| Agent | Checks |
|-------|--------|
| `clean-architecture-reviewer` | Layer boundaries, rich entities, value objects, DTO mapping, composition root |
| `test-quality-reviewer` | Coverage mapping, edge cases, determinism, Swift Testing usage, test-first history |
| `accessibility-auditor` | Contrast, Dynamic Type, VoiceOver, 44pt targets, reduce motion |
| `design-fidelity-checker` | The running screen against the `.pen` design |

Findings that are worth fixing become `fix:` or `refactor:` commits.

### 2.6 Documentation and close-out
- **Doc comments** (`doc-comments-pass`): only after the tests are green and the feature commits are done. Comments are added to public types and functions where the name and signature do not already say what they do, explaining the why. This is its own `docs:` commit, never mixed into `feat:` or `refactor:`.
- **Phase file and `PLAN.md`:** update the status and record any decision that changed after the build, so the docs match the code.
- **Process log** (`process-log`, optional): write what was done, which Claude features helped, what went wrong and what to repeat.

### 2.7 Pull request
- Run the relevant suite one last time.
- Check that no secret is staged (the local `Secrets.xcconfig` stays git-ignored).
- Push the branch and open a PR against `main`. The description summarizes the phase, links its phase file, and lists what was verified and what was not.
- After the PR is open, CI is watched and failures can be fixed on the branch.

## 3. Where the human decides
Claude drives most of the work, but these checkpoints stay with the human:

1. The idea and its scope.
2. Every decision in the kickoff (with a recommendation, never a silent default).
3. Permission for project-file edits, dependencies and anything outward-facing (pushing, opening the PR).
4. Which review findings to act on.
5. The final merge.

## 4. A variant: features that live on their own branch
For the Claude-powered features, the planning docs live on `main` but the finished implementation lives on a separate branch. Anyone can follow the phase files on `main` to reproduce the process, or check out the branch to see the result. See the main [README](../../README.md).

## 5. Quick reference: skills and agents

**Skills** (`.claude/skills/`): `phase-kickoff`, `tdd-cycle`, `define-location`, `naming-convention`, `new-value-object`, `new-use-case`, `new-ds-component`, `new-screen`, `design-to-swiftui-spec`, `create-preview`, `accessibility-check`, `doc-comments-pass`, `process-log`.

**Agents** (`.claude/agents/`): `component-builder`, `clean-architecture-reviewer`, `test-quality-reviewer`, `accessibility-auditor`, `design-fidelity-checker`.
