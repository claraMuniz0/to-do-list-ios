# Designing around the Claude API vs. a typical REST backend: technical decisions

It records how the to-do iOS app treats Claude as a **backend dependency** (not as a coding assistant), and how that differs from consuming a conventional REST API. Decisions come from the confirmed phase docs: [claude-foundation.md](../phases/claude-related/claude-foundation.md), [phase-8-steps.md](../phases/claude-related/phase-8-steps.md) and [phase-9-smart-add.md](../phases/claude-related/phase-9-smart-add.md). Companion to [claude-features-phases-process-log.md](claude-features-phases-process-log.md).

> **Status of this document.** Sections 1 to 7 describe decisions made at planning time and, where the build changed them, say so under **"As built"**. The code reviewed is the Claude layer on branch `feat-adding-claude-feature` (`ToDoList/Data/Claude/`). Section 8 holds the author's own observations.

## TL;DR

- **What:** an iOS to-do app where Claude is part of the product: *Smart Add* turns one sentence into a task draft, and *Steps* suggests how to break a task down.
- **How:** the Anthropic Messages API called directly with `URLSession`, a forced tool call for structured output, `claude-haiku-5-5`, and a protocol in front of it so the domain never knows Claude exists.
- **Main finding:** the service layer (client, error mapping, tests) looked like a REST integration. The difference is in what happens *after* a successful call: the answer can be valid and still wrong for the product, so every answer is re-validated and a human reviews it before anything is saved.
- **Limits:** gibberish still becomes a task, and steps can be too detailed for vague input (see section 10).

## 1. The two Claude features

| Feature | User sees | What Claude does |
|---|---|---|
| **Smart Add** (Phase 9) | Types "Dentist next Tuesday at 3pm. Bring insurance card." and taps "Fill it in" | Turns free text into a structured task draft: title, description, category, due date, optional steps |
| **Steps** (Phase 8) | Taps "Break it down" or "Suggest more" on a task | Proposes 3 to 6 short, actionable steps for a task title and description |

Both are **extraction/generation with a strict output shape**, not open-ended chat. That choice drives most of the decisions below: the less freedom the model has, the closer it behaves to a normal API.

## 2. How a Claude call differs from a REST call

| Concern | Typical REST backend | Claude Messages API | Design consequence here |
|---|---|---|---|
| **Contract** | Fixed schema, versioned endpoint | Schema is a *request*: the model is asked to follow it | Force a tool call and validate the result again (3.2, 5) |
| **Determinism** | Same input, same output | Same input can give different output | Tests never assert on model text; the user reviews before saving (5, 6) |
| **Failure modes** | Transport and status codes | Transport and status codes **plus** a successful response that is wrong, empty or off-schema | Two error layers: transport errors and "unusable answer" errors (4) |
| **Latency** | Tens to hundreds of ms | Seconds, grows with output length | Small model, capped output, explicit loading state, 20 s timeout (3.3, 4) |
| **Cost** | Flat or per request | Per token, input and output | Send the minimum, cap `maxTokens`, no automatic retries (3.3, 4) |
| **Input trust** | Validated by your code | Free text goes into a prompt | Treat the *output* as untrusted too (5) |
| **Behavior change** | Only when you deploy | Prompt wording and model version change behavior | Prompt in one constant, model in one constant (3.1, 3.3) |
| **Privacy** | Your own server | Text leaves the device to a third party | Send only what is needed and say so in the UI (7) |

## 3. Decisions

### 3.1 Call the Anthropic API directly from the app, with plain `URLSession`
- **Chosen:** `POST https://api.anthropic.com/v1/messages` through `URLSession` and `Codable`, behind a `ClaudeClient` protocol. No SDK, no backend proxy.
- **Why:** one endpoint; the global rules forbid adding packages without permission; roughly 100 lines to maintain; and a protocol boundary keeps the client replaceable.
- **Trade-off:** the API key ships in the app binary (see 7). This is acceptable only for a personal, development-only build. A real release would need a backend that holds the key and proxies requests, which also would be the place for rate limiting and per-user quotas.
- **As built:** the client sends `Authorization: Bearer <key>` instead of the `x-api-key` header, and the base URL is configurable (`AnthropicBaseURL` in the build config, defaulting to the Anthropic host). The reason is that access to the API goes through a **company gateway**, which expects a bearer token. A malformed or unset base URL falls back to the default host, and an unset key (the literal `$(NAME)` placeholder left in the plist) counts as missing. So "no backend proxy" is true for our code, but a gateway still sits in the path; the request and response shapes are the standard Messages API.
- **Considered and rejected:** a Python backend. Python cannot run inside an iOS app, so it would mean standing up and hosting a service, which is out of proportion for a learning project.

### 3.2 Structured output through a forced tool call, not "reply in JSON"
- **Chosen:** each feature declares one tool (`create_task_draft`, `suggest_steps`) whose `input_schema` is the shape we want, and sets `tool_choice` to that tool. The tool input is decoded into a DTO.
- **Why:** it constrains the reply to the schema far more reliably than parsing JSON out of prose (no code fences, no preamble, no trailing commentary).
- **Still not a guarantee:** values can be semantically wrong (an unknown category id, an impossible date, an empty title). The schema narrows the problem; it does not remove validation (see 5).

### 3.3 Smallest model that does the job, capped output
- **Chosen:** `claude-haiku-5-5` held in a single constant; `maxTokens` capped per request.
- **Why:** both features are short structured extraction, where speed matters more than depth, so the sheet should feel instant and cost stays low.
- **Trade-off:** slightly weaker on ambiguous sentences. Switching to `claude-sonnet-5-5` is a one-constant change, and the fakes make it safe to compare.

### 3.4 Prompts are code: one constant per feature, written for a closed task
Smart Add system prompt contains: the role, the **allowed category ids**, **today's date**, "date only, no times", "ignore priority", "answer in the language of the sentence", and "do not invent".
Steps system prompt contains: concise and imperative, 3 to 6 steps, same language as the task, no numbering; for "Suggest more" it also receives the existing steps and is told to return new, non-overlapping ones.

**As built, one decision was revised.** The Smart Add prompt now says "always give 3 to 6 short, concrete, imperative steps" (using the steps the user listed when there are any), instead of the planned "steps only if the user listed them". Reason: the Review screen should open with the Steps field already filled, which is a better first impression than an empty field. The cost is that steps are now model-generated content the user did not ask for, so the protection against a wrong or unwanted step is the human review before saving (section 5), not the prompt. Title, description and due date still follow "do not invent": description and `due_date` are left out unless the sentence says them.

The Smart Add system prompt is built per call (`systemPrompt(for:)`) because it embeds today's date and the live category ids; the Steps prompt is a true constant.

Principles behind them:
- **Give the model the context it cannot know** (today's date, the current categories) instead of hoping it guesses. Relative dates such as "next Tuesday" are resolved by Claude from the date we supply, then parsed by our code as `YYYY-MM-DD`.
- **Say what *not* to do** ("do not invent", "no times") because over-helpful output is the common failure of extraction prompts.
- **Keep prompts out of views and view models.** They live in the Data layer so they can be tested and changed in one place.

### 3.5 The domain never knows Claude exists
```
Presentation  ->  Domain (ports + use cases)  <-  Data (Claude implementations)
                  StepSuggesting                  ClaudeStepSuggester
                  TaskDraftParsing                ClaudeTaskDraftParser
                                                  AnthropicMessagesClient (URLSession)
```
- Domain defines the ports (`StepSuggesting`, `TaskDraftParsing`) and the value objects the answers must satisfy (`TaskDraft`, `StepTitle`, `SmartAddText`).
- Data holds everything provider-specific: request building, the tool schema, DTOs, HTTP.
- **Why this matters more than usual:** a REST backend is stable enough that leaking its shape is merely untidy. A model's behavior moves, so the rest of the app should only depend on "give me a valid `TaskDraft` or an error".

## 4. Errors: two layers, never swallowed

**Layer 1, transport (`ClaudeError`):** `missingAPIKey`, `offline`, `timeout`, `rateLimited` (429), `unauthorized` (401), `serverError(status)` (5xx, including the API's overloaded status), `invalidResponse`.

**Layer 2, semantic (feature errors):** the call succeeded but the answer is unusable, for example `SmartAddError.couldNotUnderstand` when there is no title, or a steps result that is empty after validation. This layer does not exist in most REST integrations.

**As built, the two layers are mapped into a smaller UI vocabulary.** `ClaudeStepSuggester` and `ClaudeTaskDraftParser` translate transport errors into feature errors (`StepSuggestionError`, `SmartAddError`): `offline` stays distinct, and every other `ClaudeError` (timeout, rate limit, unauthorized, server error, invalid response) becomes a generic `failed` ("Something went wrong. Try again."). A reply with the wrong tool name or undecodable input is also `failed`; a reply with no usable title is `couldNotUnderstand`. This was an intentional MVP simplification: the user only needs "you're offline" or "try again". The detailed `ClaudeError` remains available at the Data boundary if logging or finer messages are added later. A cancelled request (the user closes the screen) is not treated as an error: the view model resets to idle.

Rules:
- **No automatic retry.** A 20 s timeout surfaces as `timeout` and the user taps "Try again". Retries would multiply token cost and make behavior and tests harder to predict.
- **The user's input is kept** on every failure, so retrying costs nothing to re-type.
- **Errors are shown inline** (danger text plus "Try again", with its own copy for offline) and announced to VoiceOver.
- **A missing key hides the Claude entry points** (no dead buttons); the manual flows keep working. The app degrades to a normal to-do list.

## 5. Handling non-determinism and untrusted output

1. **Validate every field again in Data.** Lengths, category ids, dates and titles are checked as if they came from a stranger: titles are trimmed and must be non-empty, an unknown or missing category falls back to Personal, a date must be exactly `YYYY-MM-DD` and not in a year before today's, otherwise it becomes `nil` (the check is on the year, so a date earlier in the current year is not rejected), an overlong title is cut to the 120-character limit rather than rejected, and blank or too-long steps are dropped one by one so a single bad entry does not fail the whole answer. For Steps, `SuggestStepsUseCase` also removes titles that duplicate existing steps (case-insensitive) and stops at the room left under the 20-step cap.
2. **Domain value objects are the final gate.** A model answer only becomes a `TaskDraft` if it can be built from `TodoItemTitle`, `DueDate`, `StepTitle` and so on.
3. **A human reviews before anything is saved.** Smart Add ends on a Review screen that is the normal Add form prefilled, with a banner saying so. Claude proposes; the user decides. This is the cheapest and strongest defence against a confident wrong answer.
4. **Do not invent.** Optional fields stay empty when the sentence does not contain them; steps appear only if the user listed them.

## 6. Testing an API that does not repeat itself

- **No network in the test suite.** A `URLProtocol` stub tests the HTTP client (request shape: headers, body, forced tool choice; success decode; each error status; timeout; offline). A hand-written `FakeClaudeClient` (queued responses and errors) tests the features.
- **We test our code's behavior around the model**, not the model: success, partial answer, malformed answer, empty title, bad date, unknown category, over-length input, and every error case.
- **A live check is a documented manual step**, not an automated test, because it is slow, costs money, needs a key and cannot give a stable assertion.
- **Gap to be honest about:** this proves the plumbing and validation are correct, not that the prompt gives *good* answers. Prompt quality needs a small set of real example sentences run by hand (and re-run after any prompt or model change).

## 7. Privacy and key handling

- **What leaves the device:** only the text the user typed, or the task title and description, plus category names and today's date. No ids, no other tasks.
- **Said out loud in the UI:** the Smart Add privacy line reads "Claude fills the form. Your text is sent to Claude. You review before saving." The original design copy did not mention that data leaves the device.
- **Key:** read from a git-ignored `Secrets.xcconfig` into an `Info.plist` key at build time, with a committed `Secrets.example.xcconfig`. It is never committed, logged or printed.
- **Known limit:** the key is recoverable from the shipped binary, so this setup is for development and personal builds only, never an App Store build.

## 8. What surprised me

Observations from the author after building and running the features:

- **The course material transferred directly.** Much of what I saw in the Claude API course showed up in the real feature almost unchanged, in particular giving Claude **tools** and forcing a tool call to get structured output.
- **Calls are fast.** For these short extraction and generation tasks the responses came back quickly, well inside the 20 s timeout, so the loading state is brief.
- **Haiku was enough.** `claude-haiku-5-5` handled both features comfortably; there was no need to move to a larger model.
- **The networking layer looked like a REST one.** I do not have deep experience building networking layers, but what we wrote (a request type, a protocol-backed client, `URLSession`, status-code mapping to errors, `Codable` bodies, a stub for tests) felt very close to what we built for a REST API. The differences were mostly *around* the call (prompt, schema, validating a successful but possibly wrong answer), not in the transport itself.

- **The "always propose steps" rule paid off.** Even for very short sentences with no date and no extra detail, Claude returned useful steps (around three), so Review opened with something worth keeping. This supports the revised decision in 3.4, although it is an impression from manual runs, not a measured result.

- **Category and date came out right.** A sentence such as "Review John's doc from work until next Tuesday" landed in the *Work* category (not the Personal fallback) with the correct date, and "shopping" worked the same way. The category fallback and the date checks exist for bad prompts.
- **Title and description were faithful.** Claude did not rewrite or add to what was typed.
- **Steps are where the model over-delivers.** With a vague prompt the steps can be far more detailed than wanted: "Make a chocolate cake for my nephew" produced a recipe (gather the ingredients, preheat the oven, how long to bake) instead of a few high-level steps. The answer is valid and passes every check, it is just not what a to-do step should be. Two consequences: the user has to know that a generic prompt can produce unexpected steps, and the prompt does not yet say *how detailed* a step should be (it only says "short, concrete, imperative"). This is the clearest example in the project of a response that is **correct by the schema and still not right for the product**, which no status-code or schema check can catch. The human review step is what absorbs it, since the steps can be edited or removed before saving.

- **Nonsense input still produces a "valid" task.** Typing gibberish such as "dasdajhdvsa" did not trigger the unusable-answer path. Claude still called the tool and returned steps such as "clarify what the task means", "write down the first concrete action needed" and "set a reminder or time to work on it". The reason is structural: `couldNotUnderstand` only fires when the title is empty, and the prompt asks for steps *always*, so the model has every incentive to produce something. Claude is being helpful, not wrong, but the "unusable answer" layer designed for this case never caught it. Rejecting meaningless input would need an explicit way for the model to say "this is not a task" (for example an optional flag in the tool schema or an instruction to leave the title empty), because the app cannot tell gibberish from a short real title by looking at the string. The title itself came back identical to the typed text. **Decision: keep this limitation for now**, relying on the review screen, and revisit it if the feature grows.
- **Testing the service layer felt like testing a REST client.** Building the Claude layer, the tests had the same shape as for a REST integration: a `URLProtocol` stub for the HTTP client (request shape, status codes, timeout, offline) and a hand-written fake client for the features. The difference is not in the mechanics but in what the tests cannot prove: they show that the request is built correctly and that answers are validated, not that the prompt produces *good* answers (see the chocolate cake and gibberish cases above), which still needs manual runs.

## 9. Summary: what to carry to the next project

- Treat the model as an **unreliable but useful dependency**: constrain it, validate it, and keep a human in the loop for anything persisted.
- **Narrow tasks beat open-ended ones.** Forced tool output, a small model and a closed prompt made this behave almost like an API.
- **Put a port in front of it.** Domain-level interfaces made the model swappable and the tests network-free.
- **Plan for the success that is wrong**, not only for the failure that throws. Two real cases: vague input ("make a chocolate cake") produced steps far more detailed than a to-do needs, and gibberish still produced a "valid" task with generic steps. Both passed every check.
- **A prompt rule that says "always" removes the model's way out.** Asking for steps every time made Review feel useful, but it also meant the model never signals "this is not a task". If rejecting bad input matters, give the model an explicit way to say so.
- **Say how detailed the output should be**, not only what shape it has. "Short, concrete, imperative" did not stop recipe-level steps.
- **The service layer is ordinary engineering; the prompt is the part that needs manual testing.** The client, error mapping and tests looked like a REST integration, but only manual runs show whether the answers are good.
- **Decide cost and privacy up front**: cap tokens, avoid hidden retries, and be explicit with users about what is sent.

## 10. Limitations and next steps

**Known limitations (kept on purpose for now)**
- **Gibberish becomes a task.** Meaningless input still produces a title and generic steps, because the prompt always asks for steps and `couldNotUnderstand` only fires on an empty title. The review screen is the only defence.
- **Steps can be too detailed.** Vague prompts such as "Make a chocolate cake" can return recipe-level steps. The prompt does not say how detailed a step should be.
- **Generic errors in the UI.** Only `offline` is distinct; timeouts, rate limits, auth failures and server errors all show "Something went wrong. Try again."
- **The key lives in the binary.** Acceptable for a personal development build behind a company gateway, not for an App Store release.
- **No automatic retry.** A transient failure needs a manual "Try again".
- **Quality is checked by hand.** The automated tests cover plumbing and validation, not whether the prompt gives good answers.

**What we did not build**
- Streaming responses, prompt caching, conversation memory, a backend proxy with per-user limits, and speech input.

**Possible next steps**
- Let the model say "this is not a task" (an optional flag or an empty title) so gibberish can be rejected.
- Tell the prompt how coarse a step should be, then compare the output on a fixed list of example sentences.
- Keep that list of sentences as a small manual regression set, rerun after any prompt or model change.
- Map more `ClaudeError` cases to specific messages, and log them.