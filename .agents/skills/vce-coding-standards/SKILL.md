---
name: vce-coding-standards
description: >
  Coding, linting, typing and testing standards for the VCE research template.
  Use this skill whenever you write, edit, review or test Python, R, C++/Rcpp or
  JavaScript code: new modules, functions, CLI scripts, notebooks turned into
  code, pytest or testthat tests, imports and dependencies, ruff / basedpyright
  runs, PR diffs, or reproducibility of statistical and machine-learning
  experiments. Load it BEFORE producing any code so formatting, typing and
  test conventions are applied from the start.
---
<!-- markdownlint-disable MD013 -->

# vce-coding-standards

Apply every rule in the relevant section before delivering code.
Prefix every tool with `uv run` (see `AGENTS.md`).

## Definition of done (Python)

1. Edit the file. (If the Claude Code hook is active, `ruff` already ran; otherwise run step 2.)
2. Lint-fix, **then** format — fixes can change formatting, so this order matters:

   ```bash
   uv run ruff check --fix <file>
   uv run ruff format <file>
   ```

3. Type-check the touched files: `uv run basedpyright <file>`
4. Run the relevant tests: `uv run pytest <test_file> -xvs`
5. Zero new `ruff` / `basedpyright` findings. Do not silence with `# noqa` / `# type: ignore` unless justified in a comment.

## Python

### Imports

- All imports at the **top of the file**.
- Valid exceptions only: circular imports (restructure first; document if not possible), lazy loading for worker isolation, `TYPE_CHECKING` blocks.

### Style

Formatting is defined by `[tool.ruff]` in `pyproject.toml` — never override it in code.
Conventions that formatters cannot enforce: `references/python-style.md`.

### Testing

- **Framework:** `pytest` patterns only — no `unittest.TestCase`.
- **Location:** `tests/pytest/`, mirroring the `src/` structure.
- **Coverage:** success, failure and edge cases for every new behaviour.
- **Mocking:** use `spec` / `autospec`.
- **Parametrisation:** `@pytest.mark.parametrize` for multiple similar inputs.
- **Markers:** register every custom marker (`slow`, `gpu`, …) in `pyproject.toml`; do not invent unregistered ones.
- **Fixtures:** shared fixtures live in `pytest_plugin.py` under `tests/pytest/` (find with `fdfind pytest_plugin.py tests`).
- **Determinism:** seed all randomness; no network, GPU or wall-clock dependence in unit tests; use `tmp_path` for files.

```bash
uv run pytest path/to/test.py::TestClass::test_method -xvs   # single test
uv run pytest path/to/test.py -xvs                           # file
uv run pytest path/to/package -xvs                           # package
```

### Research reproducibility

- Randomness only through an explicit generator: `rng = numpy.random.default_rng(seed)`; `seed` is a function/CLI parameter, never a hidden global.
- No absolute paths. Use `pathlib.Path` relative to the project root; data in `data/`, intermediate output in `temp/`, logs in `logs/`.
- Use `logging`, not `print`, in library code.
- Never commit data, model artefacts or notebook outputs.

## R (container only)

Details: `references/r.md`. Run scripts with `./runtime.sh rs <script>` from the host, or `uv run Rscript <script>` inside the container.
R is **not** available natively.

## JavaScript / JupyterLab

- Package manager: `jlpm` (yarn-compatible), always via `uv run`.
- Install / update: `uv run jlpm up && uv run jlpm install`.
- Scope: JupyterLab extensions and optional skill scripts (`package.json`).
- Never mix application logic into the `docker/` subtree.

## C / C++

Follow Rcpp CRAN guidelines for Rcpp coding. Prefer RcppArmadillo over RcppEigen unless requested.
Run `Rcpp::compileAttributes()`, `devtools::document()` and `devtools:check()` to validate. The only CRAN violatiom admitted is the `-march=native` annotation about portability.
Use "Google C/C++ Style Guideline" for code.


## Julia

Keep package code in `src/Dve.jl` unless requested. Different position may require affition in `.Rbuildignore` to avoid warmings.
Put scripts under `exec/` directory
To implement cross-language integration use

- Julia->Python: `PythonCall`
- R->Julia: `JuliaCall`
- Python->Julia: `JuliaCall`
  

## Rust / Node

No project-wide standard is defined yet. Match the surrounding code; use a formatter
(`cargo fmt`) only if its config file is already in the repo;
ask before adding new tooling or dependencies.
