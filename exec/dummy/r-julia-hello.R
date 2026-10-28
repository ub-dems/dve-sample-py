#!/usr/bin/env Rscript

##
# r-julia ('rcall' environment) test -- specular to julia-r-hello.jl
#
# usage: run script from project root
#
# ./exec/dummy/r-julia-hello.R ...
#

suppressPackageStartupMessages(library(argparse))

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

parse_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  parser <- ArgumentParser(
    description = r"---(
Print a Julia and R greeting.

R and Julia (in-process) interop demo.

- R->Julia: "JuliaCall"    R Package (GitHub), in-process (default)
- R->Julia: "JuliaConnectoR" CRAN R package, out-of-process (--proc)
- Julia->R: "RCall.jl"     Julia Module, nested R->Julia->R (--full)

see: src/Dve.jl
see: R/dummy-fun.R

NOTE:

With --proc, RCall.jl runs in the Julia sub-process and starts its own
embedded R session (no in-process R/Julia nesting).
)---",
    epilog = r"---(
run as (from project base directory):

 ./exec/dummy/r-julia-hello.R Alice Bob
 ./exec/dummy/r-julia-hello.R -F Alice Bob
 ./exec/dummy/r-julia-hello.R -P Alice Bob
 ./exec/dummy/r-julia-hello.R -P -F Alice Bob
 ./exec/dummy/r-julia-hello.R -v -s 'Hi' Alice Bob
 ./exec/dummy/r-julia-hello.R -v -F -s 'Hi' Alice Bob
 ./exec/dummy/r-julia-hello.R -v -P -F -s 'Hi' Alice Bob
 ./exec/dummy/r-julia-hello.R --demo
 ./exec/dummy/r-julia-hello.R --help
)---",
    formatter_class = "argparse.RawDescriptionHelpFormatter"
  )

  parser$add_argument(
    "-F", "--full", action = "store_true",
    help = "enable RCall.jl (Julia->R) callbacks, i.e. R->Julia->R"
  )
  parser$add_argument(
    "-P", "--proc", action = "store_true",
    help = "use JuliaConnectoR (R->Julia) sub-process calls instead of in-process JuliaCall"
  )
  parser$add_argument(
    "-D", "--demo", action = "store_true",
    help = "enable extra JuliaCall/JuliaConnectoR (and RCall with -F) demos"
  )
  parser$add_argument(
    "-s", "--salutation", default = "Hello", metavar = "WORD",
    help = "greeting word [default: %(default)s]"
  )
  parser$add_argument(
    "-v", "--verbose", action = "store_true",
    help = "verbose logging"
  )
  parser$add_argument(
    "who", nargs = "+",
    help = "who to greet"
  )

  opts <- parser$parse_args(args)

  if (isTRUE(opts$verbose)) {
    for (arg in sort(names(opts))) {
      cat(sprintf("  %s  =>  %s\n", arg, paste(format(opts[[arg]]), collapse = " ")))
    }
  }
  opts
}

# ---------------------------------------------------------------------------
# Julia backends: JuliaCall (in-process, default) / JuliaConnectoR (--proc)
#
# Both expose the same minimal interface:
#   $name, $setup(), $import(pkg), $call(fn, ...), $eval(code), $shutdown()
# ---------------------------------------------------------------------------

require_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("R package '%s' is required but not installed", pkg), call. = FALSE)
  }
}

julia_backend_inproc <- function(full, verbose) {
  require_pkg("JuliaCall")
  list(
    name = "JuliaCall",
    # useRCall = TRUE lets the embedded Julia load RCall.jl (R->Julia->R)
    setup = function() {
      JuliaCall::julia_setup(useRCall = full, verbose = verbose)
      invisible(NULL)
    },
    import   = function(pkg) JuliaCall::julia_library(pkg),
    call     = function(fn, ...) JuliaCall::julia_call(fn, ...),
    eval     = function(code) JuliaCall::julia_eval(code),
    shutdown = function() invisible(NULL)   # Julia lives inside this R process
  )
}

julia_backend_proc <- function(full, verbose) {
  require_pkg("JuliaConnectoR")
  list(
    name = "JuliaConnectoR",
    # Julia sub-process is started lazily; force it now
    setup = function() {
      invisible(JuliaConnectoR::juliaEval("VERSION"))
    },
    import   = function(pkg) invisible(JuliaConnectoR::juliaImport(pkg)),
    call     = function(fn, ...) JuliaConnectoR::juliaCall(fn, ...),
    eval     = function(code) JuliaConnectoR::juliaEval(code),
    shutdown = function() try(JuliaConnectoR::stopJulia(), silent = TRUE)
  )
}

make_backend <- function(proc, full, verbose) {
  if (proc) julia_backend_proc(full, verbose) else julia_backend_inproc(full, verbose)
}

# ---------------------------------------------------------------------------
# R side
# ---------------------------------------------------------------------------

init_r_session <- function(verbose) {
  devtools::load_all(".", quiet = !verbose)
}

show_r_status <- function() {
  print(utils::sessionInfo())
}

hello_from_r <- function(salutation, who) {
  # NOTE: assumes dmy_hello(<who>, salutation = ) -- see R/dummy-fun.R
  say <- vapply(who, function(w) dmy_hello(w, salutation = salutation),
                character(1), USE.NAMES = FALSE)
  writeLines(say)
}

# ---------------------------------------------------------------------------
# Julia side (R -> Julia), through the selected backend
# ---------------------------------------------------------------------------

init_julia_session <- function(jl) {
  jl$setup()
  jl$import("Dve")
}

show_julia_status <- function(jl) {
  jl$eval("import Pkg")
  jl$eval("Pkg.status()")
  invisible(NULL)
}

julia_demo <- function(jl) {
  jl_sum <- jl$call("sum", c(1.0, 4.0, 6.0))
  cat(sprintf("jl_sum=%s\n", format(jl_sum)))
  cat(sprintf("jl_version=%s\n", jl$eval("string(VERSION)")))
}

hello_from_julia <- function(jl, salutation, who) {
  say <- lapply(who, function(w) jl$call("Dve.hello_world", salutation, w))
  writeLines(as.character(unlist(say)))
}

# ---------------------------------------------------------------------------
# R -> Julia -> R (Julia calls back into R via RCall.jl)
# ---------------------------------------------------------------------------

# Julia code defined at runtime; function-call API of RCall.jl only
# (no R"..." macros, they need RCall loaded at macro-expansion time).
julia_rcall_code <- r"---(
function hello_via_rcall(salutation, who)
    # out-of-process: RCall starts its own embedded R, load the project there.
    # in-process: dmy_hello already exists in the host R session, so a no-op.
    reval("if (!exists('dmy_hello')) devtools::load_all('.')")
    who = who isa AbstractString ? [who] : collect(who)
    return Any[rcopy(rcall(:dmy_hello, w; salutation = salutation)) for w in who]
end
)---"

julia_rcall_demo_code <- r"---(
function rcall_demo()
    r_sum = rcopy(rcall(:sum, Float64[1.0, 4.0, 6.0]))
    r_cols = rcopy(reval("names(mtcars)"))
    return Any[r_sum, r_cols]
end
)---"

init_julia_rcall <- function(jl, demo) {
  jl$eval("using RCall")
  jl$eval(julia_rcall_code)
  if (demo) jl$eval(julia_rcall_demo_code)
  invisible(NULL)
}

show_r_status_cb <- function(jl) {
  # R sessionInfo(), as seen from Julia through RCall.jl
  jl$eval("print(rcall(:sessionInfo))")
  invisible(NULL)
}

rcall_demo <- function(jl) {
  res <- jl$call("rcall_demo")
  cat(sprintf("r_sum=%s\n", format(res[[1]])))
  cat(sprintf("r_mtcars_names=%s\n", paste(res[[2]], collapse = " ")))
}

hello_from_r_cb <- function(jl, salutation, who) {
  say <- jl$call("hello_via_rcall", salutation, who)
  writeLines(as.character(unlist(say)))
}

# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

process <- function(opts) {
  verbose    <- isTRUE(opts$verbose)
  full       <- isTRUE(opts$full)
  proc       <- isTRUE(opts$proc)
  demo       <- isTRUE(opts$demo)
  salutation <- opts$salutation
  who        <- opts$who

  init_r_session(verbose)

  if (verbose) show_r_status()

  jl <- make_backend(proc, full, verbose)
  init_julia_session(jl)
  on.exit(jl$shutdown(), add = TRUE)

  if (verbose) show_julia_status(jl)

  if (demo) julia_demo(jl)

  hello_from_r(salutation, who)

  hello_from_julia(jl, salutation, who)

  if (full) {
    init_julia_rcall(jl, demo)

    if (verbose) show_r_status_cb(jl)

    if (demo) rcall_demo(jl)

    hello_from_r_cb(jl, salutation, who)
  }

  0L
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- parse_cli(args)

  rc <- tryCatch(
    process(opts),
    error = function(e) {
      message("error: ", conditionMessage(e))
      1L
    }
  )

  shutdown(rc)
  rc
}

shutdown <- function(rc) {
  # Skip .Last()/finalizers: avoids teardown races between the host R
  # and an embedded Julia (JuliaCall) or its nested embedded R (RCall.jl).
  quit(save = "no", status = rc, runLast = FALSE)
}

if (!interactive() && sys.nframe() == 0L) {
  main()
}
