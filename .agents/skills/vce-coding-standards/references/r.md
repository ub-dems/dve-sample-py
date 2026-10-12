# R conventions

R runs only in the Podman container. From the host: `./runtime.sh rs <script>`.
Inside the container: `uv run Rscript <script>`.

- **Environment:** managed by `renv`; lock-file changes (`renv.lock`) are explicit, reviewed commits — never hand-edit.
- **Tests:** `testthat` under `tests/testthat/`, one `test-<file>.R` per `R/<file>.R`.
- **Documentation:** roxygen2 comments in `R/`; regenerate `man/` and `NAMESPACE` (e.g. `devtools::document()` if installed); never hand-edit them.
- **Rcpp:** after changing `src/*.cpp` exports, run `Rcpp::compileAttributes()`; `RcppExports.*` are generated.
- **Style:** follow the surrounding code; use `styler` / `lintr` only if their config is present in the repo.
- **Reproducibility:** `set.seed()` once at the entry-point, seed passed as a parameter; no absolute paths.
