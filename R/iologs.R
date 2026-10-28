# Logging Configuration and Utility Functions
# 
# Note:
#
#  - the `logging` package was replaced by `logger` package
#
#  - standard R functions: message, warning, error, stop are hooked to
#    logger channel
#
#  - legacy `logging` function calls are redirected to `logger`
#    equivalents
#
#  - a fail-safe `logger` formatter in installed in failure handling
#    to avoid formatting problems
#
#  - a file logging naming prefix, based on start timestamp, is stored
#    in options for possible usage in other script outputs
#
# ////////////////////////////////////////////////////////////////////////////

# ---(conditional logging)---------------------------------------------

init_opt_verbose <- function(args, level = 1) {
  verbose <-args_get(args, "verbose", 0)

  if (is.logical(verbose)) {
    verbose <- ifelse(verbose,1,0)
  }

  if (!(is.numeric(verbose))) {
    verbose <- 0
  }
  set_verbose(verbose)
}

set_verbose <- function(verbose = 1) {
  prev <- get_verbose()
  options("o_verbose" = verbose)
  prev
}

get_verbose <- function() {
  result <- getOption("o_verbose", 0)
  return(result)
}

is_verbose <- function(level = 1) {
  verbose = get_verbose()
  result <- ifelse(verbose >= level, TRUE, FALSE)
  return(result)
}

get_verbose_level <- function(verbose = get_verbose()) {
  result <- switch(verbose + 6, 
                   logger::OFF,      # verbose = -5
                   logger::FATAL, 
                   logger::ERROR, 
                   logger::WARN,
                   logger::SUCCESS,
                   logger::INFO,     # verbose = 0
                   logger::DEBUG,    # verbose = 1
                   logger::TRACE)
  
}

init_opt_quiet <- function(args) {
  quiet <-args_get(args, "quiet", FALSE)
  if (!(is.logical(quiet))) {
    return(FALSE)
  }
  return(quiet)
}

set_quiet <- function(quiet = TRUE) {
  prev <- is_quiet()
  options("o_quiet" = quiet)
  prev
}

is_quiet <- function() {
  result <- (getOption("o_quiet", FALSE) == TRUE)
  return(result)
}


init_logging_options <- function(args) {
  init_opt_verbose(args)
  init_opt_quiet(args)
}
  
# ---(startup diagnostics)---------------------------------------------

## Log system information
## @param name script name
## @param args parsed args as a named list
init_main_show_system_info <- function(name = "script", args = list()) {
  
  if (!(is_verbose())) {
    return(invisible(NULL))
  }  
  
    
  sys_info <- get_system_info()
  sys_info_yaml <- as.yaml(sys_info)
  message(sprintf("=== System Information === \n\n%s\n\n", sys_info_yaml))
  
  return(invisible(NULL))
  
}

## Log system information
## @param name script name
## @param args parsed args as a named list
init_main_show_arguments <- function(name = "script", args = list()) {
  args_wrap = list(script = list(name = name, args = args))
  args_yaml <- as.yaml(args_wrap)
  message(sprintf("=== Script Arguments === \n\n%s\n\n", args_yaml))
}

# ---(log marks)---------------------------------------------

mark_log_init <- function(name = NULL, args = list()) {

  script_name <- ifelse(is.null(name), getOption("o_script_name","script"), name)
  timestamp <- getOption("o_run_timestamp","?(timestamp)") 
  log_dir <- getOption("o_log_dir","?(log_dir)") 
  log_file <- getOption("o_log_file","?(log_file)") 
  log_threshold <- getOption("o_log_threshold","?(log_threshold)") 

  # Mark Log Start
  logger::log_info(">>*CTL:START: {script_name} -- at: {timestamp}")
  logger::log_info("Log file: {log_file}")
  logger::log_info("Log dir: {normalizePath(log_dir)}")
  logger::log_info("Log level: {log_threshold}")
  
}

mark_log_exit <- function(rc = 0, msg = "success.") {

  script_name <- getOption("o_script_name")

  start_time <- getOption("o_run_start_time")
  end_time <- getOption("o_run_end_time")

  timestamp <- format(end_time, "%Y%m%d-%H%M%S")
  elapsed_millis <- end_time - start_time
  duration <- format_elapsed(elapsed_millis)

  # Mark Log End
  logger::log_success("<<*CTL:END{rc} {script_name} -- at: {timestamp} (elapsed: {duration}) -- {msg}")

}

mark_log_fail <- function(rc = 1, ex = NULL, msg = "_undefined error_") {

  script_name <- getOption("o_script_name")

  start_time <- getOption("o_run_start_time")
  end_time <- getOption("o_run_end_time")

  timestamp <- format(end_time, "%Y%m%d-%H%M%S")
  elapsed_millis <- difftime(end_time, start_time, units = "secs")
  duration <- format_elapsed(as.numeric(elapsed_millis)*1000)

  # Mark Log Fail
  tryCatch({

    failsafe_setup_logging()

    em <- ifelse(is.null(ex),"#UNKERR", as.character(ex))
  
    stop_fail <- sprintf("==*CTL:FAIL(%d) %s -- at: %s (elapsed: %s) ?? %s -- %s",
                        rc, script_name, timestamp, duration, em, msg)
    # traceback()
    xt <- capture.output(traceback())

    logger::log_error(xt)
    logger::log_error(stop_fail)
    stop_fail
    
  }, error = function(ea) {
    tryCatch({
      stop_error <- sprintf("==*CTL:ABORT: ex: %s", ea)
      logger::log_error(stop_error)
      stop_error
    }, error = function(ez) {
      stop_quit <- paste("==*CTL:PANIC:", script_name )
      print(stop_quit)
      stop_quit
    })
  })

}

mark_log_quit <- function(rc = 0, msg = "terminated.") {
  quit_msg <- sprintf("QUIT: (rc=%d) %s",rc,msg) 
  if (rc == 0) {
    logger::log_success(quit_msg)
  } else {
    logger::log_fatal(quit_msg)
  }
  return(quit_msg)
}

mark_log_stop <- function(rc = 0, msg = "terminated.") {
  stop_msg <- sprintf("STOP: (rc=%d) %s",rc,msg)
  if (is_verbose()) {
    if (rc == 0) {
      logger::log_success(stop_msg)
    } else {
      logger::log_fatal(stop_msg)
    }
  }
  return(stop_msg)
}

mark_log_halt <- function(rc = 0, ex = NULL, msg = "terminated.") {
  em <- ifelse(is.null(ex), "NULL", as.character(ex))
  halt_msg <- sprintf("HALT: (rc=%d) %s -- ex=%s",rc,msg,em)
  traceback()  
  return(halt_msg)
}



# ---(`logger` setup)---------------------------------------------

# Registration hooks for standard R message functions
init_main_hook_logging <- function() {
  # warning: must be called out from a tryCatch block
  logger::log_messages()
  logger::log_warnings()
  logger::log_errors()
  return(invisible(NULL))
}

## Initialize logging facility provided by 'logger' package
## @param name script name
## @param args parsed args as a named list
init_main_setup_logging <- function(name = NULL, args = list()) {

  script_name <- ifelse(is.null(name), getOption("o_script_name","script"), name)
  
  init_logging_options(args)

  # Get log directory from environment or default
  log_dir <- dirname(io_logs("logfile.log"))
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)
  }
  options("o_log_dir"=log_dir)

  start_time <- getOption("o_run_start_time")
  timestamp <- getOption("o_run_timestamp")

  log_prefix <- sprintf("%s-%s", script_name, timestamp)
  log_file <- file.path(log_dir, sprintf("%s.log", log_prefix))
  log_threshold <- get_verbose_level()
  options("o_log_prefix"=log_prefix)
  options("o_log_dir"=log_dir)
  options("o_log_file"=log_file)
  options("o_log_threshold"=log_threshold)

  # Configure logger
  logger::log_appender(logger::appender_tee(log_file))
  logger::log_threshold(log_threshold)
  logger::log_layout(logger::layout_glue_colors)
  logger::log_formatter(logger::formatter_glue_or_sprintf)
  
  # Mark Log Start
  mark_log_init(name = script_name, args = args)

  return(list(log_dir = log_dir, log_prefix = log_prefix, log_file = log_file))
}

failsafe_setup_logging <- function() {
  
  # Configure logger
  logger::log_formatter(logger::formatter_paste)
  return(list(log_formatter = logger::formatter_glue_or_sprintf))
}


# ////////////////////////////////////////////////////////////////////////////

## Log system information
## @param name script name
## @param args parsed args as a named list
init_script_show_system_info <- function(name = "script", args = list()) {
  
  if (!(is_verbose())) {
    return(invisible(NULL))
  }  
  
    
  sys_info <- get_system_info()
  sys_info_yaml <- as.yaml(sys_info)
  message(sprintf("=== System Information === \n\n%s\n\n", sys_info_yaml))
  
  return(invisible(NULL))
  
}

## Log system information
## @param name script name
## @param args parsed args as a named list
init_script_show_arguments <- function(name = "script", args = list()) {
  args_wrap = list(script = list(name = name, args = args))
  args_yaml <- as.yaml(args_wrap)
  message(sprintf("=== Script Arguments === \n\n%s\n\n", args_yaml))
}



# ////////////////////////////////////////////////////////////////////////////

# legacy `logging` package support

logfinest <- function(msg, ...) {
  logger::log_trace(sprintf(msg,...))
}

logfiner <- function(msg, ...) {
  logger::log_trace(sprintf(msg,...))
}

logfine <- function(msg, ...) {
  logger::log_trace(sprintf(msg,...))
}

logdebug <- function(msg, ...) {
  logger::log_debug(sprintf(msg,...))
}

loginfo <- function(msg, ...) {
  logger::log_info(sprintf(msg,...))
}

logwarn <- function(msg, ...) {
  logger::log_warn(sprintf(msg,...))
}

logerror <- function(msg, ...) {
  logger::log_error(sprintf(msg,...))
}

# ## @deprecated("removed logging dependency, replaced by logger package")
# ## init logging
# ##
# ## @param logfile String logfile under logs/ (.gitignored) dir
# ## @param args list args, defaults to command-line arg
# ## @param loglevel String appender logging level
# ## @param filelevel String logfile logging level
# ## @param outlevel String console logging level
# ## @export
# log_init <- function(logfile = "logfile.log", args = c(), loglevel='DEBUG', filelevel='DEBUG', outlevel='INFO'){
#   logdir <- dirname(io_logs("logfile.log"))
#   if (!dir.exists(logdir)) {
#     dir.create(logdir, showWarnings = FALSE, recursive = TRUE)
#   }
#
#   logging::basicConfig()
#   logging::setLevel(loglevel)
#   logging::addHandler(logging::writeToFile, file=log_file(logfile), level=filelevel)
#   logging::setLevel(Sys.getenv("R_LOGGING_LEVEL", outlevel), getHandler("basic.stdout"))
# }

# ////////////////////////////////////////////////////////////////////////////
