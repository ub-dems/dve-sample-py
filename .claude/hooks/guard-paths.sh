#!/usr/bin/env bash
# PreToolUse hook (Bash): Read/Edit deny rules do not cover shell commands,
# so block the two boundaries that matter most: ./home/ and .env.
# Fails CLOSED: without jq the command cannot be inspected, so it is refused.
command -v jq >/dev/null 2>&1 || { echo "Blocked: jq is required by the path guard hook." >&2; exit 2; }
cmd=$(jq -r '.tool_input.command // empty')
home_re='(^|[[:space:]"=:'"'"'])(\./)?home/'
env_re='(^|[[:space:]])\.env([[:space:]]|$)'
if printf '%s' "$cmd" | grep -Eq "$home_re"; then
  echo "Blocked: ./home/ is a security boundary (see AGENTS.md > Boundaries)." >&2
  exit 2
fi
if printf '%s' "$cmd" | grep -Eq "$env_re"; then
  echo "Blocked: do not read .env directly; pass it with 'uv run --env-file=.env'." >&2
  exit 2
fi
exit 0
