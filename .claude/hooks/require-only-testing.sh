#!/bin/bash
# PreToolUse hook (Bash): refuse `xcodebuild test` runs that are not scoped with -only-testing.
command=$(jq -r '.tool_input.command // ""')

if echo "$command" | grep -Eq 'xcodebuild[^|;&]*[[:space:]]test([[:space:]]|$)' && ! echo "$command" | grep -q -- '-only-testing'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked: run only the relevant suite with -only-testing:ToDoListTests/<Suite>, in the background, and kill it after 30s (macOS has no `timeout`). Ask the user before running the full suite. See CLAUDE.md."
    }
  }'
fi
exit 0
