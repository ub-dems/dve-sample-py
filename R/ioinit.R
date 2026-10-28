# Script Initialization and Termibnation Functions
#
# Note:
#
#  - command-line parsed argument `args` stored in options
#  - log channel configuarion via `logger` package
#  - random number generator initializazion with manual/random seed
#  - script termination logging with elasped times
#  - script failure reporting
#
# ////////////////////////////////////////////////////////////////////////////

## retrieve an optional argument fron the named list of parsed arguments.
## if missing, the value is retrieved fron system environment 
## with "X_ARG_" prefix and uppercase name.
## If the value is nyumeric, this value is converted
## as numeric from string.
##
## @param args parsed arguments as a named list
## @param name argument name
## @param default default value
## @return argument value or default value
## @export
args_get <- function(args, name, default = NA) {
  result <- default
  if (name %in% names(args$options)) {
    result <- args$options[[name]]
  } else {
    env_value <- Sys.getenv(paste0("X_ARG_", toupper(name)))
    if (!is.na(env_value)) {
      if (is.numeric(default) && is.numeric(env_value)) {
        result <- as.numeric(env_value)
      } else {
        result <- env_value
      }
    }
  }
  result
}

reserve_options <- function(options, reserved) {
  options
}

add_std_options <- function(p, reserved = c()) {
  p <- optparse::add_option(p, reserve_options(c("-v", "--verbose"), reserved),
    action = "store_true", default = FALSE,
    help = "Increase verbosity (-v: debug) [default %default]"
  )

  p <- optparse::add_option(p, reserve_options(c("-l", "--log-level"), reserved),
                            action = "store", default = "AUTO",
                            help = "Logger Level: if AUTO, use verbose, (OFF|ERROR|WARN|INFO|DEBUG|TRACE) [default %default]"
  )
  
  p <- optparse::add_option(p, reserve_options(c("-q", "--quiet"), reserved),
    action = "store_true", default = FALSE,
    help = "Suppress diagnostic output [default %default]"
  )

  p <- optparse::add_option(p, reserve_options(c("-r", "--rng-seed"), reserved),
    type = "integer", default = 0,
    help = "Random seed for reproducibility (0 = random) [default %default]"
  )

  return(p)
}

make_std_option_parser <- function(prog = NULL, usage = "",
                                   description = "", epilogue = "", std = FALSE) {
  p <- optparse::OptionParser(
    prog = prog, usage = usage,
    description = description, epilogue = epilogue
  )
  if (std) {
    p <- add_std_options(p)
  }
  return(p)
}

# ////////////////////////////////////////////////////////////////////////////

rc_get <- function() {
  options("o_rc")
}

rc_set <- function(rc = 0) {
  options("o_rc" = rc)
}


# ////////////////////////////////////////////////////////////////////////////

## Initial setup for random number generator (rng)
## @param name script name
## @param args parsed args as a named list
## @param seed seed to assign, if 0, retrieved from args or env, only set if defined
## @return the seed assigned to param seed seed to assign, if 0, retrieved from args or env, only set if defined
init_main_setup_rng <- function(name = "script", args = list(), seed = 0) {
  env_seed <- as.integer(Sys.getenv("R_SEED", unset = "0"))
  env_seed <- ifelse(is.na(env_seed) == TRUE, 0, env_seed)
  arg_seed <- args_get(args, "rng_seed", env_seed)

  if (is_verbose()) {
    message(sprintf("Random SEED.init: arg=%d  env=%d", arg_seed, env_seed))
  }

  if (seed == 0) {
    seed <- arg_seed
  }
  if (seed == 0) {
    seed <- as.integer(runif(1) * 2e9)
  }
  set.seed(seed)
  options("o_rng_seed" = seed)
  message(sprintf("Random SEED: %d   (start: %f)", seed, runif(1)))
  seed
}

# ---(script execution mode)-------------------------------------------

set_script_mode <- function(script_mode = TRUE) {
  options("o_script_mode" = script_mode)
}

is_script_mode <- function() {
  result <- (getOption("o_script_mode", FALSE) == TRUE)
  result
}

halt_script <- function(rc = 0, ex = NULL, msg = "terminated.") {
  halt_msg <- mark_log_halt(rc = rc, ex = ex, msg = msg)
  stop(halt_msg)
}

stop_script <- function(rc = 0, msg = "terminated.") {
  stop_msg <- mark_log_stop(rc = rc, msg = msg)
  stop(stop_msg)
}

quit_script <- function(rc = 0, msg = "terminated.") {
  if (!(is_script_mode())) {
    stop_script(rc = rc, msg = msg)
    return(rc) # never
  }

  mark_log_quit(rc = rc, msg = msg)
  quit(status = rc)
}

# ////////////////////////////////////////////////////////////////////////////

# ---(main control functions)-------------------------------------------

init_main_store_options <- function(name = "script", args = list()) {
  script_name <- name
  start_time <- Sys.time()
  timestamp <- format(start_time, "%Y%m%d-%H%M%S")

  options("o_script_name" = script_name)
  options("o_run_args" = args)
  options("o_run_start_time" = start_time)
  options("o_run_timestamp" = timestamp)
}

exit_main_store_options <- function(rc = 0, msg = "success.") {
  end_time <- Sys.time()
  options("o_run_end_time" = end_time)
  options("o_rc" = rc)
}

fail_main_store_options <- function(rc = 0, ex = NULL, msg = "success.") {
  exit_main_store_options(rc = rc, msg = msg)
  options("o_ex" = ex)
}


## init script
##
## @param name script name
## @param args parsed args as a named list
## @return parsed args as a named list
init_main <- function(name = "script", args = list()) {
  rc <- tryCatch(
    {
      init_main_store_options(name = name, args = args)
      init_main_setup_logging(name = name, args = args)
      init_main_show_arguments(name = name, args = args)
      init_main_setup_rng(name = name, args = args)
      init_main_show_system_info(name = name, args = args)
      0
    },
    error = function(ex) {
      halt_script(rc = 1, ex = ex, "fatal error in init_main()")
    }
  )
  # Inject hooks in base logging (outside a tryCatch block)
  init_main_hook_logging()

  args
}

## exit script
##
## @param rc return code
## @param msg message
## @export
exit_main <- function(rc = 0, msg = "success.") {
  exit_main_store_options(rc = rc, msg = msg)
  mark_log_exit(rc = rc, msg = msg)

  rc
}

## fail script
##
## @param rc return code
## @param ex error
## @param msg message
## @export
fail_main <- function(rc = 1, ex = NULL, msg = "_undefined error_") {
  fail_main_store_options(rc = rc, ex = ex, msg = msg)
  stop_msg <- mark_log_fail(rc = rc, ex = ex, msg = msg)

  quit_script(rc = rc, msg = stop_msg) # no return
  rc
}

# ---(run task)------------------------------------------------

run_task <- function(f, argv = c()) {
  rc <- 0
  logger::log_info("#> start: %s", paste(argv, sep = " "))
  elapsed <- system.time({
    rc <- f()
  })
  logger::log_info("#< end(%d): %s", rc, summary(elapsed))
  rc
}

# ---(script control functions)-------------------------------------------

## script invocation mode setting
##
## @export
enter_script <- function() {
  set_script_mode()
}

## quit R with return code if script invocation
##
## @param rc return code
## @param msg exit message
## @export
exit_script <- function(rc = 0, msg = "terminated.") {
  quit_script(rc = rc, msg = msg)
}


# ////////////////////////////////////////////////////////////////////////////
