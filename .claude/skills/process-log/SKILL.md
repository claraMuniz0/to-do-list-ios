---
name: process-log
description: Write a process log in docs/process/ that records how a piece of work was done with Claude Code (timeline, features used, method, what went wrong, what to repeat), in the format of ai-assisted-planning-log.md. Trigger when the user asks for a process log, a session write-up, an article-material doc, or "a doc like the ai-assisted-planning-log". Writes docs only, never app code.
---

# Process log

Goal: a factual record of how a session or stretch of work went, for later review and as raw material for an article. Model it on `docs/process/ai-assisted-planning-log.md` (read it first for tone and structure).

## Procedure
1. **Gather facts, don't recall.** Read the session's own evidence: `git log` and `git status` for the period, the phase/doc files touched, and the conversation. List what was asked, what was delivered, what was decided and by whom.
2. **Write `docs/process/<topic>-process-log.md`** with these sections, in order (drop one only if truly empty):
   1. Context (app, constraints, the request, the result in one line)
   2. Timeline table: `Step | What happened | Claude features used`
   3. The working method (what was read programmatically, decision tables, how the user was asked, knock-on edits)
   4. Skills, agents and tools created or used (tables)
   5. What went well / problems found by planning / friction and corrections
   6. Numbers (files, decisions, commits, lines of code; only what you counted)
   7. Suggested article angle (titles, structure)
   8. What I would do differently
   9. Reproducing this (numbered steps)
   10. Where things are (paths)
3. **Be honest.** Include mistakes, late discoveries, changes of direction by the user, and unverified claims. A log that only lists wins is useless. Say "not tracked" for anything not measured (time, tokens); never invent numbers.
4. **Never include secrets**: no API keys, `.env` contents, keychain data, tokens, or personal emails.
5. **Link, don't copy**: reference phase files by relative path rather than pasting their tables, except one short excerpt if it illustrates a pattern.
6. Match the language and tone of the existing log (plain, first person where the user speaks, short bullets).
7. Do not commit unless the user asks; if asked, use a `docs:` commit.

## Rules
- Only files under `docs/process/` are written.
- Facts must be checkable against the repo or conversation; mark anything uncertain as such.
