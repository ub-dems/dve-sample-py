---
name: vce-project-scripts
description: >
  How to run the project-level scripts: build.sh, runtime.sh, setup.sh, lab.sh,
  the root Makefile and docker/r-image/Makefile. Use this skill whenever you need
  to build, test, lint or document the project via the scripts, manage Podman
  images or containers, run Python or R batch scripts in the container, or start
  JupyterLab / RStudio. It also says which commands an agent may run, which need
  approval and which are for the human only. Load it BEFORE invoking any of
  those scripts.
---
<!-- markdownlint-disable MD013 -->

# vce-project-scripts

Run `<script> --help` for the full option list. Legend for the **Agent** column:

- ✅ run freely  · ⚠️ ask the user first  · ⛔ human only (interactive, server, GUI or handles credentials)

## Which mode am I in?

```bash
if [ -n "${container:-}" ] || [ -f /run/.containerenv ]; then echo container; else echo native; fi
```

| Mode          | Rule                                                                                                   |
|---------------|--------------------------------------------------------------------------------------------------------|
| **native**    | `build.sh build\|test\|check\|docs` and `uv run …` work directly. R is unavailable: use `runtime.sh` to reach it. |
| **container** | Already inside Podman: do **not** call `runtime.sh` (no nested Podman). Use `./build.sh …` or `uv run …` directly. |

> The wrapper behaviour inside a container and the R part of `build.sh test` on a native install
> are not described in this repository; if a command fails because of the mode, report it instead of guessing.

## Script entry-points

| Script                    | Purpose                                                              |
|---------------------------|----------------------------------------------------------------------|
| `build.sh`                | Build, test, lint, docs and container-image commands                 |
| `runtime.sh`              | Container lifecycle and interactive session commands                 |
| `setup.sh`                | Initialise virtual environments (`--external` = native install under the user home) |
| `lab.sh`                  | JupyterLab launcher; `lab.sh --version` prints the tool versions     |
| `Makefile`                | Core command implementation, invoked by the scripts above            |
| `docker/r-image/Makefile` | Low-level `podman` interface (normally called by the scripts above)  |

## build.sh

### Project commands (native **and** container)

| Command          | Effect                                      | Agent |
|------------------|---------------------------------------------|-------|
| `build.sh build` | Build the project (Python + R)              | ✅    |
| `build.sh test`  | Run project tests (Python + R)              | ✅    |
| `build.sh check` | Run linters and static checks (Python + R)  | ✅    |
| `build.sh docs`  | Generate project documentation (Python + R) | ✅    |

### Container image lifecycle

| Command            | Effect                                                             | Agent |
|--------------------|--------------------------------------------------------------------|-------|
| `build.sh setup`   | Initial image creation (long, needs network)                       | ⚠️    |
| `build.sh update`  | Update existing images                                             | ⚠️    |
| `build.sh upgrade` | **Deletes `uv.lock` and `renv.lock`** to force a full upgrade      | ⚠️    |
| `build.sh full`    | `setup` + virtual-environment installation in the persistent volume | ⚠️   |

## runtime.sh

| Command                  | Effect                                                              | Agent |
|--------------------------|---------------------------------------------------------------------|-------|
| `runtime.sh environment` | Imports `~/.config` and **SSH keys** into `home/user/`              | ⛔    |
| `runtime.sh setup`       | Runs `setup.sh` inside the container                                | ⚠️    |
| `runtime.sh build\|test\|check` | Same as `build.sh …`, executed inside the container          | ✅    |
| `runtime.sh pyrun <args>`| `uv run python <args>` inside the container                         | ⚠️ if long-running, GPU or network-heavy; otherwise ✅ |
| `runtime.sh rs <args>`   | `uv run Rscript <args>` inside the container                        | ⚠️ (same)  |
| `runtime.sh sh`, `python`, `R`, `term`, `xterm` | Interactive shell / REPL / terminal          | ⛔    |
| `runtime.sh rstudio`     | RStudio Server, port `28787`                                        | ⛔    |
| `runtime.sh lab`, `notebook` | JupyterLab / Notebook, port `28888`                             | ⛔    |
| `runtime.sh code`, `cursor`, `antigravity` | IDEs (need an X-Window)                       | ⛔    |

For ⛔ commands, tell the user the exact command to run in their own terminal.

## Long-running commands

Builds, image setup and experiments can exceed an agent's command timeout and flood the context.

```bash
mkdir -p logs
nohup ./build.sh test > logs/test-$(date +%F-%H%M).log 2>&1 &
tail -n 50 logs/test-*.log        # poll; use rg to search for failures
```

- Always redirect output to `logs/` (git-ignored) and read only the tail or the matches.
- Never `sleep`-loop for more than a few seconds; check back with `tail`.
