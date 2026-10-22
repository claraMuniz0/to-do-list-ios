# To-Do List iOS

A native iOS to-do app built with **SwiftUI** and **SwiftData**, following **Clean Architecture** and **Test-Driven Development**. It is also an experiment: the whole project was planned, designed and built together with Claude, and the process is documented so you can reproduce it.

> **Looking for the finished app with the Claude-powered features (Smart Add and Steps)?** Check out the [`feat-adding-claude-feature`](../../tree/feat-adding-claude-feature) branch. See [Branches](#branches).

## Features on `main`

- Welcome / empty state and a branded splash screen (Reduce Motion honored)
- Add, edit and delete tasks (title, description, category, due date), with an Undo toast
- Task list with open and completed sections, swipe to delete and an "All caught up" state
- Filters (Active / Done / Categories), search with recent searches, and three sort orders
- Custom categories (name and color, with a live preview)
- A design system with reusable components, built from design tokens (colors, fonts, radii)
- Accessibility: VoiceOver labels, Dynamic Type, 44pt touch targets

The planned scope and the status of each phase live in [`docs/phases/PLAN.md`](docs/phases/PLAN.md).

## How this project was built

The project was built **docs first, code second**. Before writing any app code, we created the scaffolding that would guide Claude through the whole build:

1. **Skills** in [`.claude/skills/`](.claude/skills): reusable procedures such as `phase-kickoff`, `tdd-cycle`, `new-value-object`, `new-use-case`, `new-ds-component`, `new-screen`, `define-location`, `naming-convention`, `create-preview`, `accessibility-check`, `doc-comments-pass` and `process-log`.
2. **Agents** in [`.claude/agents/`](.claude/agents): specialised helpers such as `component-builder`, `clean-architecture-reviewer`, `test-quality-reviewer`, `accessibility-auditor` and `design-fidelity-checker`.
3. **Docs and phases** in [`docs/phases/`](docs/phases): one file per phase, each with its goal, decisions table and "done when" criteria. A phase is confirmed with the `phase-kickoff` skill *before* any code is written.
4. **Process logs** in [`docs/process/`](docs/process): write-ups of how the planning and the building went, including what went wrong and what to repeat.

Every phase then follows the same loop: kick off the phase, confirm the decisions, then red → green → refactor in small commits (`test:`, `feat:`, `refactor:`), a doc-comment pass in its own `docs:` commit, and independent reviews by the reviewer agents.

### Design

The entire design was drawn in **[pen.dev](https://pen.dev)** with **Claude as the design agent**, through the Pencil MCP server. The design file (`to-do.pen`) is the source of truth for every screen and component: Claude reads it to produce a SwiftUI spec (`design-to-swiftui-spec` skill) and checks the running app against it (`design-fidelity-checker` agent).

## Branches

| Branch | What it contains |
|--------|------------------|
| `main` | The app up to the non-Claude phases (0 to 7 and 10), plus **all** the docs, skills, agents and phase files, including the ones for the Claude features. |
| [`feat-adding-claude-feature`](../../tree/feat-adding-claude-feature) | The full result of the Claude-powered phases: the Claude foundation, **Phase 8 (Steps, with "Break it down" and "Suggest more")** and **Phase 9 (Smart Add)**. |

The docs for the Claude features ([`docs/phases/claude-related/`](docs/phases/claude-related)) live on `main`, but their implementation lives on a separate branch on purpose. That gives you two ways to use the repo:

- **Reproduce the process.** Stay on `main`, open the Claude-related phase files and build the features yourself with Claude, using the same skills and agents. Handy if you are curious how it works.
- **See the final result.** Check out `feat-adding-claude-feature` and run the finished app.

```bash
git checkout feat-adding-claude-feature
```

## Architecture

Three layers with strict, inward-only dependencies:

| Layer | Folder | Contents |
|-------|--------|----------|
| Domain | `ToDoList/Domain` | Rich entities (`TodoItem`), self-validating value objects (`TodoItemTitle`, `DueDate`, `CategoryName`), use cases and repository protocols. Pure Swift, no frameworks. |
| Presentation | `ToDoList/Presentation` | SwiftUI views and `@Observable` view models, one folder per feature. |
| Data | `ToDoList/Data` | Repository implementations (SwiftData, UserDefaults, in-memory), storage records and mappers to the domain. |

`ToDoList/Shared` holds the design system, and `ToDoList/AppDependencies.swift` is the composition root. Tests mirror this structure in `ToDoListTests/`, with hand-written test doubles instead of mocking frameworks.

## Getting started

**Requirements:** Xcode with the iOS 27 SDK (the project's deployment target is iOS 27.0).

```bash
git clone <repo-url>
cd to-do-list-ios
open ToDoListApp.xcodeproj
```

Pick the `MyApp` scheme and an iOS Simulator, then press **Run**. `main` needs no API key and no extra setup.

### Running the tests

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ToDoListTests
```

Adjust the simulator name to one you have installed.

### Claude features (`feat-adding-claude-feature` branch only)

Smart Add and Steps call the Anthropic API. To enable them, copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` (git-ignored) and fill in your own credentials. Debug builds only: the values ship inside the app binary, so never use a production key in a build you distribute. Without a key, the rest of the app works normally.

## Using Claude Code on this repo

Open the repo with [Claude Code](https://claude.com/claude-code) and the skills and agents are picked up automatically. A good starting point:

> Kick off Phase 9.

That triggers the `phase-kickoff` skill, which turns the phase file into confirmed decisions before any code is written.

## Documentation

- [`docs/phases/PLAN.md`](docs/phases/PLAN.md): the macro plan and the status of every phase
- [`docs/phases/`](docs/phases): one detailed file per phase
- [`docs/process/`](docs/process): process logs of the planning and the build
- [`docs/licenses/fonts/`](docs/licenses/fonts): licenses of the bundled fonts

## Credits and licenses

Fonts: Fraunces, Bricolage Grotesque, Outfit, Caveat and DM Mono, all under the SIL Open Font License (see [`docs/licenses/fonts`](docs/licenses/fonts)).

Designed with [pen.dev](https://pen.dev), planned and built with [Claude Code](https://claude.com/claude-code).
