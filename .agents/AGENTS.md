# AGENTS instructions
<!-- markdownlint-disable MD013 -->

## Environment

### Tools available on `$PATH` (user home)

- `uv`, `uvx`, `npm`, `npx`

### Tools available in project virtual environment

- `python`, `ruff`, `pyright`, `jupyter`, `jlpm` (yarn)

### System utilities

- GNU coreutils: `cat`, `grep`, `awk`, `find`, `sed`, `cut`, …
- `perl` (basic), `rg`, `fdfind`, `exa` (rust), `curl`, `wget`, `ftp`, `scp`
- `markdownlint-cli2`, `jq`, `yq`

> **Rule:** Never run `pytest`, `python`, `pyright`, `ruff`, or `yarn` directly.
> Always prefix with `uv run …` (see Commands below).

### Environment

Always detect for `.env` file in project root. If present, add option `--env-file` to `uv run` commands, in this way: `uv run --env-file=.env ...`

---

## Commands

| Task                | Command                                                |
|---------------------|--------------------------------------------------------|
| Single test         | `uv run pytest path/to/test.py::Class::method -xvs`    |
| Test file           | `uv run pytest path/to/test.py -xvs`                   |
| Package tests       | `uv run pytest path/to/package -xvs`                   |
| Run Python script   | `uv run python dev/my_script.py`                       |
| Jupyter CLI         | `uv run jupyter --notebook-dir=notebooks --no-browser` |
| Type check          | `uv run pyright path/to/code`                          |
| Lint                | `uv run ruff check --fix <file>`                       |
| Format              | `uv run ruff format <file>`                            |
| License check       | `uv run reuse lint`                                    |
| Install Python deps | `uv lock && uv sync --all-extras --all-groups`         |
| Install Node deps   | `uv run jlpm up && uv run jlpm install`                |
| Manual checks       | `prek run --from-ref <target_branch> --stage manual`   |
| Build docs          | `bash ./build.sh docs`                                 |

---

## Project Scopes

- **Domain:** data-science and statistics research experiments
- **Languages:** Python, R, JavaScript, Markdown (mixed)
- **Runtimes:** Native and rootless-containerised (`podman`)
- **Virtual envs:** `uv` (Python) · `renv` (R, explicit) · `jlpm`/yarn (JS/JupyterLab)

---

## Commits and PRs

Write commit messages focused on **user impact**, not implementation details.

- ✅ `Fix airflow dags test command failure without serialized Dags`
- ✅ `UI: Fix Grid view not refreshing after task actions`
- ❌ `Initialize DAG bundles in CLI get_dag function`

---

## Boundaries

**Ask first before:**

- Large cross-package refactors
- New dependencies with broad impact
- Destructive data or migration changes

**Never:**

- Commit secrets, credentials, or tokens
- Edit generated files by hand when a generation workflow exists
- Use destructive git operations unless explicitly requested

---

## Skills (auto-loaded on demand)

The following project skills extend this file.
They are referenced here and included verbatim in `.claude/CLAUDE.md`.

| Skill                  | Triggers                                                                |
|------------------------|-------------------------------------------------------------------------|
| `vce-project-layout`   | navigating source tree, locating files, understanding directory roles   |
| `vce-project-scripts`  | running build/container/runtime commands via `build.sh` or `runtime.sh` |
| `vce-coding-standards` | writing, editing, reviewing, or testing Python/R/JS code                |
