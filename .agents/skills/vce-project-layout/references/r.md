# R layout

Apply when `project.layout = 'R'`. R runs **only inside the Podman container**.

| Path                 | Role                                                |
|----------------------+-----------------------------------------------------|
| `R/`                 | R package functions                                 |
| `exec/`              | R (out-of-packege) executable scripts               |
| `etc/R/Makevars`     | Mapped as `~/.R/Makevars` inside containers         |
| `man/`               | Auto-generated R documentation — **never edit**    |
| `vignettes/`         | R vignettes (`knitr`)                               |
| `tests/testthat/`    | `testthat` unit tests                               |
| `renv/`, `renv.lock` | `renv` configuration / lock (explicit commits only) |
| `DESCRIPTION`        | R package description                               |
| `inst/extdata/ext/`  | Local datasets (git-ignored)                        |
| `inst/python/`       | base python package source directory                |
| `inst/include/`      | C/C++ package interface, generated code             |
| `src/`               | C/C++ for Rcpp; `RcppExports.*` are generated       |
| `src/Dve.jl`         | Julia main package module                           |

Placement rules:

- New R function → `R/<topic>.R` with roxygen2 comments; regenerate `man/` and `NAMESPACE`, never hand-edit them.
- New test for `R/foo.R` → `tests/testthat/test-foo.R`.
- New C++ functions → `src/<topic>.cpp` with roxygen2 comments; regenerate `inst/include`, `man/` and `NAMESPACE`, never hand-edit them.
- Command-line scripts → `exec/`.
