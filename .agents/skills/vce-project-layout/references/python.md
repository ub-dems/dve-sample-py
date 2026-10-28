# Python layout

Apply when `project.layout = 'python'`.

| Path                    | Role                                                                  |
|-------------------------+-----------------------------------------------------------------------|
| `src/`                  | Application source code                                               |
| `src/*/cli/__main__.py` | Main CLI entry-point (declared in `pyproject.toml [project.scripts]`) |
| `src/*/scripts/`        | Alternative "in-package" script entry-points                          |
| `src/vce/`              | Shared utility library                                                |
| `notebooks/`            | Jupyter notebooks                                                     |
| `exec/`                 | Alternative "out-of-package" executable scripts                       |
| `tests/pytest/`         | pytest unit tests (mirror the `src/` package structure)               |
| `doc/`                  | Sphinx documentation (`*.rst`)                                        |
| `data/`                 | Local datasets (git-ignored)                                          |
| `pyproject.toml`        | `uv`-based PEP 621 project definition                                 |
| `.venv/`, `.venv.cdk/`  | `uv` virtual environments — **do not touch**                         |

Placement rules:

- New library code → `src/<package>/`; new CLI → `src/<package>/cli/`; one-off entry-point → `src/<package>/scripts/`.
- New test for `src/a/b.py` → `tests/pytest/` in the matching sub-path.
- Exploratory work → `notebooks/`; never import from a notebook.
