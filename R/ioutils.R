# Miscellaneous Utility Functions
# 
# Note:
#
#  - the resolved paths are relative to project root
#
#  - the project root is resolved looking for standard files in parent directories
#    via `rprojroot::find_root_file`
#
#  - the function `fn_base` most be customized to point the main data directories:
#      * private local  fsys: `def_path(fn)` `inst/extdata/ext/{fn_base()}.def/{fn}`
#      * shared  local  fsys: `loc_path(fn)` `inst/extdata/ext/{fn_base()}.loc/{fn}`
#      * network remote fsys: `net_path(fn)` `inst/extdata/ext/{fn_base()}.net/{fn}`
#
#  - the `io_path` function ensure that all directories on the requested path
#    are created, if missing
#
#  - during `R CMD check` phase, the `inst` part of the path is removed.
#    The `is_check_mode` can be used to skip the failing tests
#
# ////////////////////////////////////////////////////////////////////////////


# ---(format)---------------------------------------------

with_digits <- function(f, digits = 3) {
  oo <- options(digits = digits)
  result <- f()
  on.exit(options(oo))
  return(result)
}

format_elapsed <- function(elpsed_time) {
  elapsed_sec <- as.numeric(elpsed_time, unit="secs")
  ss <- elapsed_sec %% 60
  mn <- floor(elapsed_sec / 60) %% 60
  hh <- floor(elapsed_sec / 3600)
  result <- paste0(sprintf("%02.f", hh), ":",
                   sprintf("%02.f", mn), ":",
                   sprintf("%02.f", ss))
  return(result)
}

# ---(capture)---------------------------------------------

out_capture <- function(..., prefix="\n", suffix="\n") {
  # see also: rlang::enquos(), rlang::eval_tidy()
  ocap <- eval(substitute(utils::capture.output(...)), parent.frame())
  ostr <- paste(ocap, collapse = "\n")
  result <- paste0(prefix, ostr, suffix)
  return(result)
}

# ---(diagnostics)---------------------------------------------

## retrieve all installed packages with versions
##
## @return dataframe of packages and versions
## @export
list_dependencies <- function() {

  pkgs <- data.frame()
  for (i in 1:(length((.packages())))){
    package <- (.packages())[i]
    version <- utils::packageVersion(package)
    pv <- data.frame(package, version)
    pkgs <- rbind(pkgs,pv)
  }
  return(pkgs)
}

## get system information
## @returns list of system information
get_system_info <- function() {
  cpu_info <- NA
  # Try to run inxi command
  tryCatch({
    cpu_info_raw <- system("inxi -C", intern = TRUE, ignore.stderr = TRUE)
    cpu_info <- paste(cpu_info, collapse = "\n")
  }, error = function(e) {
    warning("Could not retrieve CPU info (inxi not available)")
  })
  result <- list(
    cpu_info = cpu_info,
    r_version = R.version.string,
    r_platform = R.version$platform
  )
  result
}


## get system information
## @returns list session info
get_session_info <- function() {
  session_info <- capture.output(utils::sessionInfo())
  result <- list(
    session_info = session_info
  )
  return(result)
}
