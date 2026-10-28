# AGENTS.md

<!-- markdownlint-disable MD013 -->

Shared instructions for every coding agent (Claude Code, Codex, Cursor, Copilot, …).
Claude Code–specific additions live in `.claude/CLAUDE.md`.

**Project:** research *template* for statistics, machine-learning and economics experiments.
Two sibling layouts (`python`, `R`) share one codebase.

---

## 1. Orientation — do this first

1. **Layout.** Read `meta-inf.toml` in the project root: `project.layout = 'python' | 'R'`.
   Load the `vce-project-layout` skill before creating, moving or searching for files.
2. **Execution mode.** The project runs natively or inside a rootless Podman container.
   Detect the mode with:

   ```bash
   if [ -n "${container:-}" ] || [ -f /run/.containerenv ]; then echo container; else echo native; fi
   ```

| Mode          | Setup                                                                  | Notes                                                                                   |
|---------------|------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| **native**    | `./setup.sh --external` (installs under the user home)                 | **R is not available.**                                                                 |
| **container** | image built by `./build.sh setup` (Rocker-project R image, Ubuntu 24.04) | Runs as `root`; `/root` is mounted from `./home/user`; controlled by `./runtime.sh`; Podman calls live in `docker/r-image/Makefile`. |

3. **Languages.** `./lab.sh --version` prints the authoritative list.

| Language          | Tooling                                   | Where                |
|-------------------|-------------------------------------------|----------------------|
| Python            | `uv`, `.venv`                             | native + container   |
| R                 | `renv`                                    | **container only**   |
| C / C++ / Fortran | `gcc`, `gfortran` (Rcpp for R)            | native + container   |
| Julia, Rust       | `julia`, `cargo`                          | native + container   |
| Node / JS         | `jlpm` (yarn) for JupyterLab; `npm`/`npx` | native + container   |

---

## 2. Environment

- On `$PATH` (user home): `uv`, `uvx`, `npm`, `npx`.
- In the project virtual env: `python`, `ruff`, `basedpyright`, `jupyter`, `jlpm`, `julia`.
- System: GNU coreutils, `perl` (basic), `rg`, `fdfind`, `exa`, `jq`, `yq`, `curl`, `wget`, `markdownlint-cli2`.

> **Rule:** never run `pytest`, `python`, `basedpyright`, `ruff`, `jlpm`/`yarn` or `julia` directly.
> Always prefix with `uv run …`.

- **`.env`:** if `.env` exists in the project root, use `uv run --env-file=.env …`.
  Never print, copy or commit its contents.
- **Dependencies:** before installing Python packages, detect the GPU and pick the extra:

  ```bash
  if type nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then export X_UV_EXTRA=gpu; else export X_UV_EXTRA=cpu; fi
  ```

  After editing `pyproject.toml`: `uv lock && uv sync --extra=$X_UV_EXTRA --all-groups`.
  The `cpu` and `gpu` extras are mutually exclusive, so they must be declared under
  `[tool.uv] conflicts` in `pyproject.toml`.

---

## 3. Commands

### Python (native, or inside the container)

| Task                | Command                                                                         |
|---------------------+---------------------------------------------------------------------------------|
| Single test         | `uv run pytest path/to/test.py::Class::method -xvs`                             |
| Test file           | `uv run pytest path/to/test.py -xvs`                                            |
| Package tests       | `uv run pytest path/to/package -xvs`                                            |
| Run Python script   | `uv run python exec/my_script.py ...`                                           |
| Python Type check   | `uv run basedpyright path/to/code`                                              |
| Python Lint         | `uv run ruff check --fix <file>`                                                |
| Python Format       | `uv run ruff format <file>`                                                     |
| License check       | `uv run reuse lint`                                                             |
| Install Python deps | add to pyproject.toml and `uv lock && uv sync --extra=$X_UV_EXTRA --all-groups` |
| Install R deps      | add to DESCRIPTION then `uv run Rscript -e 'renv::install(); renv::snapshot()'` |
| R Rcpp stubs        | `uv run Rscript -e 'Rcc::compileAttributes()'`                                  |
| R Project Test      | `uv run Rscript -e 'devtools::test()'`                                          |
| R Project Document  | `uv run Rscript -e 'devtools::document()'`                                      |
| R Project Check     | `uv run Rscript -e 'devtools::check()'`                                         |
| Run R script        | `uv run Rscript exec/my_script.r ...`                                           |
| Install Julia deps  | `uv run julia -e 'using Pkg; Pkg.add("PkgA","PkgB")'`                           |
| Run Julia script    | `uv run env -S julia --color=yes --startup-file=no exec/my_script.jl ...r`      |
| Install Node deps   | `uv run jlpm up && uv run jlpm install`                                         |
| Manual checks       | `uv run prek run --from-ref <target_branch> --stage manual`                     |
| Jupyter (human)     | `./lab.sh`                                                                      |

### Project level (both modes) — see skill `vce-project-scripts`

| Task                  | Command                  |
|-----------------------|--------------------------|
| Build / test / check  | `./build.sh build\|test\|check` |
| Build docs            | `./build.sh docs`        |

### R (container only)

| From the host                      | Inside the container                |
|------------------------------------|-------------------------------------|
| `./runtime.sh rs path/to/script.R` | `uv run Rscript path/to/script.R`   |
| `./runtime.sh test`                | `./build.sh test`                   |

---

## 4. Scripts

Place executable scripts  under `./exec/` folder (or in subdirectories).
Always place a correct "SheBang" (`#!`) line and make it executable `chmod a+x`
Insert a preamble for loading package code, if needed.
Use standard argument parsing libraries, documenting command-line arguments, with a `--help` option.

| Language | Shebang Line                                                       | Preamble                                    |
|----------+--------------------------------------------------------------------+---------------------------------------------|
| Python   | `#!/usr/bin/env uv run python`                                     | `from dve.config.conf import cfg # example` |
| R        | `#!/usr/bin/env uv run Rscript`                                    | `devtools::load_all(".")`                   |
| Julia    | `#!/usr/bin/env uv run env -S julia --color=yes --startup-file=no` | `using Dve`                                 |



---

## 5. Boundaries

**Always**

- Prefix tools with `uv run`.
- After touching Python: `ruff` + `basedpyright` on the touched files, and the relevant tests, before declaring a task done.
- Write AI-generated documents to `notes/agents/` (valid GitLab-flavoured Markdown).
- Seed every random number generator you introduce, and expose the seed as a parameter.

**Ask first**

- Large cross-package refactors.
- New dependencies with broad impact; any change to `uv.lock`, `renv.lock`, `pyproject.toml` dependencies.
- Destructive data or migration changes.
- Image or environment lifecycle commands: `./build.sh setup|update|upgrade|full`, `./runtime.sh setup`, `./setup.sh`.
- Long-running, GPU-heavy or network-heavy experiments (Azure compute is billed).

**Never**

- Commit secrets, credentials or tokens; read `.env`, `~/.ssh`, `~/.config` credentials.
- Access `home/` (security boundary: it holds imported SSH keys and config).
- Edit generated files by hand when a generation workflow exists
  (`man/`, `NAMESPACE`, `RcppExports.*`, `uv.lock`, `renv.lock`, rendered docs).
- Modify `.venv*/` or `node_modules/`.
- Commit datasets, logs or temp files (`data/`, `inst/extdata/ext/`, `logs/`, `temp/` are git-ignored).
- Use destructive git operations (`reset --hard`, `clean`, `checkout -- .`, `push --force`, `branch -D`) unless explicitly requested.
- Commit or push unless asked.

---

## 6. Commits and PRs

Write commit messages (imperative, ≤72 chars) focused on **user impact**, not implementation details.

- ✅ `Fix pytest collection error when data/ is missing`
- ✅ `Add --seed option to the bootstrap CLI so runs are reproducible`
- ✅ `Docs: explain how to pick the cpu or gpu extra`
- ❌ `Refactor Dataset.__init__ to use dataclass`
- ❌ `Update uv.lock`

---

## 7. Skills

Skills live in `.agents/skills/<name>/SKILL.md`. Load the matching skill **before** acting.
Agents without native skill support: open the `SKILL.md` yourself when a trigger matches.

| Skill                  | Load when…                                                                             |
|------------------------|----------------------------------------------------------------------------------------|
| `vce-project-layout`   | locating, creating or moving files; deciding where docs, tests, data or notes go       |
| `vce-project-scripts`  | using `build.sh`, `runtime.sh`, `setup.sh`, `lab.sh`, `Makefile`, Podman, servers      |
| `vce-coding-standards` | writing, editing, reviewing or testing Python / R / JS code; lint, types, pytest, testthat |

<!--
LocalWords:  esac uv Rcpp renv Jupyter deps compileAttributes PkgB jl
LocalWords:  pyproject julia Rscript env dataclass codebase Dve
-->
