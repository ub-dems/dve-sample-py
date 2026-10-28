---
name: vce-project-layout
description: >
  Where every file lives in the VCE research template (Python and R layouts):
  source, tests, notebooks, docs, datasets, containers, notes. Use this skill
  whenever you need to find, create, move or place any file, decide where
  generated documentation, tests or data should go, or check which directories
  are off-limits. Load it BEFORE creating any new file, even if the user does
  not mention layout or directories.
---
<!-- markdownlint-disable MD013 -->

# vce-project-layout

## Step 1 — detect the layout

```bash
uv run python -c "import tomllib;print(tomllib.load(open('meta-inf.toml','rb'))['project']['layout'])"
# fallback if uv is unavailable:  rg -n "^\s*project\.layout" meta-inf.toml
```

| Result     | Then read                  |
|------------|----------------------------|
| `'python'` | `references/python.md`     |
| `'R'`      | `references/r.md`          |
| missing    | infer: `pyproject.toml` ⇒ python, `DESCRIPTION` ⇒ R; if both or neither, ask the user |

Read **only** the matching reference file, then apply the shared rules below.

## Step 2 — shared rules (both layouts)

### Containerisation

> **Exclusively** for `podman`/`docker` image definitions and orchestration.
> Never place application logic here.

| Path                            | Role                                                                           |
|---------------------------------|--------------------------------------------------------------------------------|
| `docker/r-image/`               | Default image definition                                                       |
| `docker/r-image/dockerfiles/`   | OCI-compliant Dockerfiles                                                      |
| `docker/r-image/mamba/`         | micromamba environment (CUDA installation)                                     |
| `docker/r-image/scripts/`       | Image setup scripts                                                            |
| `docker/r-image/scripts/setup/` | Post-image runtime setup on the persistent volume (`home/`)                    |
| `docker/r-image/*.conf`         | Build-time / runtime customisation                                             |
| `docker/r-image/Makefile`       | Main `podman` interface (called by root `Makefile`, `build.sh`, `runtime.sh`)  |

### JavaScript / JupyterLab

| Path           | Role                                                       |
|----------------|------------------------------------------------------------|
| `package.json` | JupyterLab (and optional skill-script) module dependencies |
| `.yarnrc.yml`  | `jlpm` (yarn) configuration                                |

### Working directories (git-ignored — safe to read/write)

| Path                | Role                                   |
|---------------------|----------------------------------------|
| `data/`             | Local datasets (python layout)         |
| `inst/extdata/ext/` | Local datasets (R layout)              |
| `temp/`             | Temporary data, intermediate results   |
| `logs/`             | Log files, captured command output     |

### Off-limits

| Path            | Rule                                                              |
|-----------------|-------------------------------------------------------------------|
| `home/`         | **Never access.** Security boundary (imported SSH keys / config). |
| `.venv*/`       | `uv` virtual environments — do not touch.                         |
| `node_modules/` | Installed Node modules — ignore.                                  |

Follow `.gitignore` for every other non-versioned file.

### Generated files — never edit by hand

`uv.lock`, `renv.lock`, `man/`, `NAMESPACE`, `RcppExports.*`, rendered docs.
Change the source (`pyproject.toml`, roxygen comments, …) and regenerate.

### Documentation

| Path            | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| `notes/agents/` | ✏️ **All AI-generated documents go here.** Valid GitLab-flavoured Markdown (GLFM); name files `YYYY-MM-DD-topic.md`. Check with `markdownlint-cli2 notes/agents/**/*.md`. |
| `notes/howtos/` | ✏️ Saved LLM queries (analysis / project usage), GLFM                    |
| `notes/custom/` | 🔒 Emacs `org-mode` customisation for project cloning — do not overwrite |
| `notes/ref/`    | 🔒 Bibliography (BibLaTeX)                                               |
| `notes/nat/`    | 🔒 `denote` annotations (`org-mode`)                                     |
| `notes/setup/`  | 🔒 Initial Python toolchain setup notes                                  |
| `notes/samples/`| 🔒 Additional code samples and optional features                         |
| `notes/styles/` | 🔒 Pandoc Markdown→PDF rendering pipeline                                |
| `doc/`          | Public project docs (Sphinx `*.rst`) — python layout                     |
| `man/`, `vignettes/` | Public R docs (generated / `knitr`) — R layout                      |
| `CITATION.cff`  | Project and related-paper references                                     |

🔒 = manual; do not overwrite.
