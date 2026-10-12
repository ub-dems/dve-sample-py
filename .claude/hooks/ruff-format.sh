#!/usr/bin/env bash
# PostToolUse hook: lint-fix, then format, any Python file Claude just edited.
# Never fails the turn: findings that --fix cannot resolve are left for the agent's own ruff run.
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in *.py) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
uv run ruff check --fix --quiet "$f" >&2 || true
uv run ruff format --quiet "$f" >&2 || true
exit 0
