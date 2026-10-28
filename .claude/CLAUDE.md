# CLAUDE.md — Claude Code additions

@../AGENTS.md

<!-- Imports resolve relative to THIS file, hence ../ . Personal overrides: CLAUDE.local.md (git-ignored). -->

## Skills

Skills are defined once, in `.agents/skills/`, and exposed to Claude Code through a
committed symlink: `.claude/skills -> ../.agents/skills`
(create with `ln -s ../.agents/skills .claude/skills`).

- Claude Code discovers skills from `.claude/skills/`; apply them automatically when their description matches.
- If the symlink is missing (e.g. a Windows checkout), read `.agents/skills/<name>/SKILL.md` directly before the task.
- Run skill scripts with the matching runner: `uv run bash`, `uv run python`, `uv run Rscript`, `uv run npx` / `node`.

## Permissions

Allow/ask/deny rules are enforced by `.claude/settings.json`, **not** by this file.
In short: read-only git, `uv run ruff|basedpyright|pytest`, and `./build.sh build|test|check|docs` run freely;
git state changes, dependency changes and image/environment lifecycle commands ask first;
`home/`, `.env`, credentials and interactive/server commands are denied.
If a command is denied, do not work around it (no alternative paths, no `sh -c` wrappers); tell the user.

## Working style

- Long output (tests, builds, experiments): redirect to `logs/` and inspect with `tail`/`rg`; run long jobs in the background (see `vce-project-scripts`).
- Never start an interactive session or a server (`runtime.sh sh|python|R|lab|rstudio|…`); tell the user the command instead.
- Use plan mode, and ask, before large cross-package refactors.
- Python edits are auto-formatted by a hook (`ruff check --fix` + `ruff format`); you still run `basedpyright` and tests.

## Compact instructions

When compacting the conversation, keep: the current task and plan; the execution mode (native/container);
files modified so far; the latest failing test/lint output; and the definitions in `src/*/scripts/` and `exec/`.
