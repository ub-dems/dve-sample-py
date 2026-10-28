#!/usr/bin/env Rscript

##
# runner script example
#

devtools::load_all(".")

require(dvesimpler)

# Load required libraries
suppressPackageStartupMessages({
  library(logger)
  library(optparse)
  library(yaml)
  library(knitr)
})

# =======================================
# Housekeeping Phase
# =======================================

c_script_name <- "dummy-runner"

c_usage_doc <- "

  'runtime' exec/dummy/dummy-runner.R [options] ...

In RStudio, the script can be run directly, always from project root,
in console, or in terminal. 

```
exec/dummy/dummy-runner.R [options] ...
```

For long running scripts,
it is better to run the script directly in command line,
inside a tmux session, to avoid disconnection interruption.
In this mode, 'runtime', from the project root, can be one of:

```sh
./runtime.sh cli exec/dummy/dummy-runner.R [options] ...
./runtime.sh sh  exec/dummy/dummy-runner.R [options] ...
```

In order to keep a complete log of script execution,
in `~/aliases`, the `rrun` function can be defined:

```sh
rrun() {
 export RR_PID=$$
 export RR_TS=$(date -Isec)
 export RR_LOG=\"logs/rrun-$(date -Isec)-$RR_PID.log\"
 ( echo \"$(date),#RRUN($RR_PID)>,ARGS=$@\"; \
   ./runtime.sh cli $@; rc=$?; \
   echo \"$(date),#RRUN($RR_PID)<,rc=$rc,ARGS=$@\") 2>&1 \
  | tee -a $RR_LOG
  echo \"$(date),#RRUN($RR_PID):rc=$rc Logfile: $RR_LOG\"
  ls -l  $RR_LOG
}
```

with this function, the script can be run as:

```sh
rrun exec/dummy/dummyRunner.R [options] ...
```

Examples:

```sh

./runtime.sh cli exec/dummy/dummyRunner.R --help
./runtime.sh cli exec/dummy/dummyRunner.R -v

rrun exec/dummy/dummyRunner.R -q alice bob

```

---

"
c_desc_doc <- "

DESCRIPTION

Demo script for simple \"hello world\" package function call.

In addition, some environment info are show in output logfile:

   - system HW summary (taken by inxi command)
   - dependency packages availabe with versions
   - R sessionInfo() output
   - renv::dignostics(), only with verbose option (-v)
   
To avoid diagnostics, run the script with the `-q,--quiet` option.


To show last log ('q' for exit) run the command:

```sh
less -SRX $(ls logs/%prog* -t | head -n1)
```

"
c_trailer_doc <- "

SEE ALSO:

   @Seealso: R/ioinit.R
   @Seealso: R/iologs.R
   @Seealso: R/iopath.R
   @Seealso: R/ioutils.R

"


# =======================================
# Global variables
# =======================================

g_script_name <- c_script_name
g_args <- NULL
g_log_dir <- NULL
g_log_prefix <- NULL
g_start_time <- NULL
g_rnd_seed <- NULL

#' store options in globals 
set_globals <- function(argv = c()) {

  assign("g_args", args, envir = .GlobalEnv)
  assign("g_run_start_time", getOption("o_run_start_time"), envir = .GlobalEnv)
  assign("g_log_dir", getOption("o_log_dir"), envir = .GlobalEnv)
  assign("g_log_prefix", getOption("o_log_prefix"), envir = .GlobalEnv)
  assign("g_rng_seed", getOption("o_rng_seed"), envir = .GlobalEnv)

  args

}

# =======================================
# Housekeeping Phase
# =======================================


#' Parse command-line arguments
parse_arguments <- function(argv = c()) {

  p <- make_std_option_parser(prog = g_script_name, usage = c_usage_doc,
                              description = c_desc_doc,
                              epilogue = c_trailer_doc)

  p <- add_option(p, c("-s", "--salutation"), default = "Hi",
                  help = "Salutation in greetings [default %default]")

  p <- add_option(p, c("-n", "--n-points"),
                  type = "integer", default = 0,
                  help = "Number of emoji for greetings [default %default]")

  p <- add_std_options(p)

  args <- parse_args(p, args = argv,
                     positional_arguments = TRUE,
                     convert_hyphens_to_underscores = TRUE)
  args
}


# //////////////////////////////////////////////////////////////////

# =======================================
# Diagnostic Info
# =======================================

show_diagnostics <- function() {
  if (!is_verbose()) {
    return(invisible(NULL))
  }
  diag <- out_capture(renv::diagnostics())
  logger::log_debug("Diagnostics: [[\n\n\n{diag}\n]]\n")
}

show_dependencies <- function() {
  pkgs <- paste(kable(list_dependencies()), collapse = "\n")
  log_info("Dependencies: [[\n\n{pkgs}\n\n]]\n")
}

show_session_info <- function() {
  sx_info <- as.yaml(get_session_info())
  log_debug("Session info: [[\n\n\n{sx_info}\n]]\n")
}

show_system_info <- function() {
  sys_info <- as.yaml(get_system_info())
  log_debug("System info: [[\n\n\n{sys_info}\n]]\n")
}

show_env_info <- function() {
  if (is_quiet()) {
    return(invisible(NULL))
  }
  show_system_info()
  show_session_info()
  show_dependencies()
  show_diagnostics()
  invisible(NULL)
}


# =======================================
# Script Tasks
# =======================================

say_hello <- function(args = g_args) {

  hello_msg <- dmy_hello()
  log_info("say_hello -- { hello_msg }")

}


say_hi_to_all <- function(args = g_args) {

  salutation <- args$options$salutation
  trailer <- paste(replicate(args$options$n_points,"👋"), collapse = "")

  if (length(args$args) == 0) { # positional arguments
    return(2)
  }

  for (who in args$args) {
    hi_msg <- dmy_hello(salutation = salutation, who = who)
    print(paste("hi.msg: ", hi_msg, trailer))
  }

  0
}


task <- function(args = g_args) {
  show_env_info()
  say_hello(args = args)
  say_hi_to_all(args = args)
}

# //////////////////////////////////////////////////////////////////

main <- function(argv = commandArgs(trailingOnly=TRUE)) {

  args <- parse_arguments(argv)
  init_main(g_script_name, args = args)

  rc <- tryCatch({
    set_globals()
    run_task(function() {
      task(args)
    }, argv = argv)
  }, error = function(ex) {
    fail_main(rc = 1, ex = ex, msg = "#FAILED!")
  })
  exit_main(rc, msg = "#success.")
}

# Execute main function if script is run directly
if (sys.nframe() == 0) {
  enter_script()
  rc <- main()
  exit_script(rc = rc)
}
