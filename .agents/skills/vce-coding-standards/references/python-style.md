# Python style (beyond ruff)

Defaults for conventions a formatter cannot enforce. `pyproject.toml` (`[tool.ruff]`) always wins;
adjust this file to the team's decisions.

- **Types:** annotate every public function and method; prefer `X | None` over `Optional[X]`; avoid `Any`.
- **Docstrings:** every public module, class and function; NumPy style (parameters, returns, raises);
  state array shapes and units for numerical code.
- **Paths:** `pathlib.Path`, never string concatenation.
- **Errors:** raise specific exceptions; no bare `except:`; no silent `except Exception: pass`.
- **Defaults:** no mutable default arguments; no work at import time.
- **Naming:** `snake_case` functions/variables, `PascalCase` classes, `UPPER_CASE` constants.
- **Numerics:** vectorise with NumPy/pandas/polars before looping; avoid in-place mutation of inputs.
- **CLI:** entry-points under `src/<package>/cli/`, declared in `[project.scripts]`.
