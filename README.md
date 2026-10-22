# To-Do List iOS: Claude features

This branch is the **finished result of the Claude-powered phases** of the To-Do List iOS app: the Claude foundation, **Phase 8 (Steps, with "Break it down" and "Suggest more")** and **Phase 9 (Smart Add)**, on top of the rest of the app.

> The project, its planning docs, skills, agents and design live on [`main`](../../tree/main). The docs for these features are on `main` too, but their implementation lives only here, on purpose. Stay on `main` if you want to **reproduce** the process yourself; use this branch if you just want to **see the result**.

## What Claude does in the app

### Smart Add

Describe a task in one sentence and Claude fills in the form for you.

> "Dentist next Tuesday at 3pm. Bring insurance card."

1. **Describe:** type up to 280 characters, or tap an example.
2. **Fill it in:** Claude returns a task draft: title, description, category, due date and a few suggested steps.
3. **Review:** the draft opens in the regular Add form with a banner ("Filled in by Claude"). Nothing is saved until you tap **Save task**, and you can edit any field first.

Design decisions worth knowing:
- Relative dates ("next Tuesday", "Friday") are resolved by Claude from today's date, then validated again in the app. A date that cannot be parsed, or that lands in the past, becomes "no date".
- Date only: times and priority in the sentence are ignored (they may stay in the description).
- Claude picks one of your **existing categories** (built-in or custom). Unknown becomes Personal.
- Claude never invents a description or a date that is not in the sentence.
- No microphone button. The keyboard's own dictation works in the text field.

### Steps

Break a task into small, trackable steps.

- **Manual:** add, tick, rename, delete and reorder steps, with a progress bar, an "N of M" count and a "2/5" badge on the task row.
- **Break it down:** on a task with no steps, Claude proposes a list in a bottom sheet. You choose which steps to keep ("Add 4 steps") or tap "Try different steps".
- **Suggest more:** with steps already present, Claude proposes additional ones that do not repeat yours.

### When there is no API key

The Claude entry points (Smart Add, Break it down, Suggest more) are **hidden, not disabled**. Without a key, the app behaves like `main`. Failures (offline, timeout, rate limit, unauthorized, bad answer) are surfaced to the user with a message and a way to try again, never swallowed.

## Screens

Drawn in [pen.dev](https://pen.dev) with Claude as the design agent. The source file and all exports are on `main` under [`design/`](../../tree/main/design).

<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/claramzfpp/to-do-list-ios/main/design/screens/14-smart-add-describe.png" width="170" alt="Smart Add: describe"></td>
    <td><img src="https://raw.githubusercontent.com/claramzfpp/to-do-list-ios/main/design/screens/15-smart-add-review.png" width="170" alt="Smart Add: review"></td>
    <td><img src="https://raw.githubusercontent.com/claramzfpp/to-do-list-ios/main/design/screens/17-edit-task-break-it-down.png" width="170" alt="Break it down"></td>
    <td><img src="https://raw.githubusercontent.com/claramzfpp/to-do-list-ios/main/design/screens/18-edit-task-suggested-steps.png" width="170" alt="Suggested steps"></td>
    <td><img src="https://raw.githubusercontent.com/claramzfpp/to-do-list-ios/main/design/screens/16-edit-task-steps.png" width="170" alt="Steps"></td>
  </tr>
</table>

## How the Claude integration is built

The integration follows the same Clean Architecture rules as the rest of the app: **Domain knows nothing about Claude.**

| Layer | What lives there |
|-------|------------------|
| Domain | Ports and pure types only: `StepSuggesting`, `TaskDraftParsing`, `SmartAddText` (trimmed, 1 to 280 chars), `Step`, `StepList`, `StepTitle`, `StepsProgress`, and the use cases that call the ports. |
| Data (`ToDoList/Data/Claude`) | `ClaudeClient` protocol and `AnthropicMessagesClient`, `ClaudeStepSuggester`, `ClaudeTaskDraftParser`, `ClaudeError`, `ClaudeAvailability`, `APIKeyProvider`. |
| Presentation | `SmartAddView` and its view model, `SuggestedStepsSheet`, `StepSuggestionState`, and the Steps design-system components (`StepRow`, `StepsField`, `StepsProgressBar`, `SmartInputField`). |

Key choices (all recorded in [`docs/phases/claude-related/`](docs/phases/claude-related)):
- **Plain `URLSession`**, no SDK and no third-party package. One endpoint, about 100 lines.
- **Forced tool call** for structured output: the request defines a tool whose input schema is the draft, so the reply is already JSON for that schema.
- **Never trust the model:** every field is validated again in Data (lengths, ids, `YYYY-MM-DD` dates) before becoming a domain object, and the user reviews before anything is saved.
- **Small, fast model:** `claude-haiku-5-5` for short structured extraction, in one constant.
- **20 second timeout, no automatic retry.** The user taps "Try again", so cost and tests stay predictable.
- **No network in tests:** the HTTP client is tested with a `URLProtocol` stub, features with a hand-written `FakeClaudeClient`.

## Getting started

**Requirements:** Xcode with the iOS 27 SDK (deployment target iOS 27.0).

```bash
git clone <repo-url>
cd to-do-list-ios
git checkout feat-adding-claude-feature
open ToDoListApp.xcodeproj
```

### Configure your API token

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig`. The copy is git-ignored.
2. Fill in your own `ANTHROPIC_AUTH_TOKEN`. To use a proxy or gateway, also set `ANTHROPIC_BASE_URL`; leave it out to use `https://api.anthropic.com`.
3. Run the `MyApp` scheme on a simulator.

> **Privacy and security:** the value is read from the app bundle, so it **ships inside the app binary**. This is for Debug builds and local development only. Never put a production key in a build you distribute, and never commit `Secrets.xcconfig`. The text you type in Smart Add, and task titles for step suggestions, are sent to the Anthropic API.

### Running the tests

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ToDoListTests
```

Adjust the simulator name to one you have installed. The suite makes no network calls.

## Reproducing this on your own

Want to build these features yourself instead of reading the result?

1. Check out `main`.
2. Open the Claude-related phase files in [`docs/phases/claude-related/`](docs/phases/claude-related): `claude-foundation.md` first, then `phase-8-steps.md` and `phase-9-smart-add.md` (independent of each other once the foundation exists).
3. Start [Claude Code](https://claude.com/claude-code) in the repo and ask it to **kick off** the phase. The `phase-kickoff` skill turns the file into confirmed decisions before any code, then the `tdd-cycle` skill drives red, green, refactor.
4. Compare your result with this branch.

The process log in [`docs/process/claude-features-phases-process-log.md`](docs/process/claude-features-phases-process-log.md) records how it went the first time, including what went wrong and what to repeat.

## Documentation

- [`docs/phases/claude-related/`](docs/phases/claude-related): Claude foundation, Phase 8 and Phase 9, with every decision and its status
- [`docs/phases/PLAN.md`](docs/phases/PLAN.md): the full plan
- [`docs/process/`](docs/process): process logs
- Back to [`main`](../../tree/main) for the general README

Designed with [pen.dev](https://pen.dev), planned and built with [Claude Code](https://claude.com/claude-code).
