# Claude Foundation (shared prerequisite for Phases 8 and 9)

**Status:** all decisions confirmed, ready to start
**Design:** none. This is infrastructure with no screen of its own.
**Depends on:** Phase 0 (layers, composition root, `DateProvider`), Phase 3 (`TodoItem`, `AddTodoItemUseCase`)
**Used by:** [Phase 8: Steps](phase-8-steps.md) (Break it down, Suggest more) and [Phase 9: Smart Add](phase-9-smart-add.md)

## Goal
One small, tested way to call Claude, so Phases 8 and 9 can be built **in parallel by two agents** without both writing a client. It is built first, by one agent, and merged before the two phase agents start. It adds no UI.

## What it contains
- **Domain (pure):** no Claude types. Only the ports each feature needs live in their own phase (`StepSuggesting` in Phase 8, `TaskDraftParsing` in Phase 9). This phase adds nothing to Domain.
- **Data:**
  - `ClaudeClient` protocol: `send(_ request: ClaudeRequest) async throws -> ClaudeResponse` (system prompt, one user message, one forced tool definition, `maxTokens`). Features build requests and decode the tool input.
  - `AnthropicMessagesClient`: `URLSession` against `POST <base URL>/v1/messages` (`Authorization: Bearer <token>`, `anthropic-version`, JSON body). No SDK. **Changed after kickoff:** the user supplies `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_BASE_URL` (gateway) in the git-ignored `Config/Secrets.xcconfig`, so auth is Bearer, not `x-api-key`, and the base URL defaults to `https://api.anthropic.com` when unset or invalid. The xcconfig is wired into Debug builds only.
  - `ClaudeError` (`missingAPIKey`, `offline`, `timeout`, `rateLimited`, `unauthorized`, `serverError(status)`, `invalidResponse`), never swallowed.
  - `APIKeyProvider` protocol and `ConfigFileAPIKeyProvider` (reads the key from the app bundle, see C1).
  - Test doubles: `FakeClaudeClient` (queued responses and errors) and a `URLProtocol` stub for the HTTP client tests.
- **Composition root:** builds the provider and the client and exposes them to both features.

## Decisions
Recommendation in **bold**. Group A answers are already given by you in the kickoff chat; the rest are `open`.

### A. Already decided (from kickoff)
| # | Decision | Answer | Status |
|---|----------|--------|--------|
| A1 | How the key reaches the app | **Key from a local config file** (git-ignored `.xcconfig` → bundle), not typed by the user and not a backend | **confirmed** (your choice) |
| A2 | Shared client so two agents can work in parallel | **Foundation first**, then Phases 8 and 9 in parallel | **confirmed** (recommendation accepted) |

### B. Client
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| B1 | HTTP layer | (1) plain `URLSession` + `Codable`; (2) a third-party package | **(1) `URLSession`.** No dependency (CLAUDE.md forbids installing packages without permission), the Messages API is one endpoint. Trade-off: we maintain ~100 lines | **confirmed** (recommendation accepted) |
| B2 | Model | (1) `claude-haiku-5-5`; (2) `claude-sonnet-5-5` | **(1) Haiku 5.5**: short structured extraction, cheapest and fastest, so the sheet feels instant. One constant, easy to change. Trade-off: slightly weaker on ambiguous sentences | **confirmed** (your choice: Haiku) |
| B3 | Structured output | (1) a forced tool call (`tool_choice`) whose `input_schema` is the draft; (2) ask for JSON in text and parse | **(1) Forced tool call.** The reply is already valid JSON for the schema; still validated again in Data (see Phases 8/9) | **confirmed** (recommendation accepted) |
| B4 | Timeout and retries | (1) 20 s timeout, no automatic retry, user taps "Try again"; (2) auto retry | **(1) No retry.** Predictable cost and tests; surfaced as `ClaudeError.timeout` | **confirmed** (recommendation accepted) |
| B5 | Tests | (1) `URLProtocol` stub for the client, `FakeClaudeClient` for features; no live calls in the suite; (2) live smoke test | **(1) No network in tests.** A manual smoke check is a documented step, not a test | **confirmed** (recommendation accepted) |

### C. Key and privacy
| # | Decision | Options | Recommendation | Status |
|---|----------|---------|----------------|--------|
| C1 | Config mechanism | `Secrets.xcconfig` (git-ignored, with a committed `Secrets.example.xcconfig`) → build setting → `Info.plist` key `AnthropicAPIKey` → `ConfigFileAPIKeyProvider` | **As described. Edits `ToDoListApp.xcodeproj/project.pbxproj` (xcconfig reference, Info.plist key): permission GRANTED for this foundation build only, nothing else in the project file.** Trade-off: the key ships inside the binary, so this is for development and personal builds only, never an App Store build | **confirmed** (recommendation accepted) |
| C2 | Missing key at runtime | (1) hide the Claude entry points ("Break it down", "Suggest more", Smart add button); (2) show them and fail on tap | **(1) Hide.** Matches Phase 3 D4 (no dead buttons); a `ClaudeAvailability` flag from the provider drives the views. Trade-off: a missing key is silent for the user, so log it once in debug | **confirmed** (your choice: hide) |
| C3 | Never commit the key | `.gitignore` entry added with the xcconfig; I never read or print `.env` or the xcconfig | **As described** | **confirmed** (recommendation accepted) |
| C4 | What leaves the device | only the text the user typed or the task title and description, plus category names and today's date; no ids, no other tasks | **As described.** The Smart Add privacy line must say the text is sent to Claude (see Phase 9) | **confirmed** (recommendation accepted) |

### D. Sequence
| # | Decision | Recommendation | Status |
|---|----------|----------------|--------|
| D1 | Order | **Build the foundation first (one agent, ends green and committed), then Phase 8 and Phase 9 in two agents on separate worktrees.** Both only add new files plus a small, agreed edit to the composition root and the form view model (conflicts handled at merge, see each phase's "Shared files") | **confirmed** (recommendation accepted) |

## Scope (after decisions are confirmed)
- [ ] `ClaudeRequest`, `ClaudeResponse`, `ClaudeError`, `ClaudeClient` (tests first)
- [ ] `AnthropicMessagesClient` with `URLProtocol` tests: request shape (headers, body, tool choice), success decode, each error status, timeout, offline
- [ ] `APIKeyProvider`, `ConfigFileAPIKeyProvider`, availability flag
- [ ] `FakeClaudeClient`
- [ ] Composition root wiring, `.gitignore`, `Secrets.example.xcconfig` (after permission for the project file)

## Out of scope
- Any screen, streaming responses, prompt caching, conversation memory, a backend proxy, a key-entry screen

## Done when
- With a stub, a request round-trips to a decoded tool input, and each `ClaudeError` case is covered.
- With a real key in the local config, a manual smoke check returns a tool input.
- Without a key, `ClaudeAvailability` is false and no Claude entry point appears.
