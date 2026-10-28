# Pathname Helper Functions
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
#    The `is_skip_mode` can be used to skip the failing tests
#
# ////////////////////////////////////////////////////////////////////////////

# ---(custom const)---------------------------------------------

fn_base <- function() { return("dve-ds") }   # <- custom


# ---(project paths)---------------------------------------------

def_path <- function(name, path, base = fn_base()) {io_data(base = base, kind = "def",path = path, name = name)}

loc_path <- function(name, path, base = fn_base()) {io_data(base=base, kind="loc", path=path, name=name) }
net_path <- function(name, path, base = fn_base()) {io_data(base=base, kind="net", path=path, name=name) }

tmp_path <- function(name, path = "") {io_temp(path = path, name = name)}
log_path <- function(name, path = "") {io_logs(path = path, name = name)}

exe_path <- function(name, path = "") {io_exec(path = path, name = name)}


# ---(path consts)---------------------------------------------

fn_temp <- function() { return("temp") }
fn_logs <- function() { return("logs") }
fn_exec <- function() { return("exec") }

fn_exdata <- function() { return("inst/extdata") }

# ////////////////////////////////////////////////////////////////////////////


# ---(io utility)---------------------------------------------

mkdirs <- function(fp) {
  if (!file.exists(fp)) {
    mkdirs(dirname(fp))
    dir.create(fp)
  }
}

ensure_path <- function(fp) {
  mkdirs(dirname(fp))
  return (fp)
}

# ---(project root)---------------------------------------------

find_test_path <- function(fp) {
  parent_path <- rprojroot::find_root_file(".", criterion = 
        rprojroot::root_criterion(function(path) dir.exists(file.path(path, "tests")), "has tests subdir"))
  sib_dirs <- list.dirs(path = parent_path, full.names = TRUE, recursive = FALSE)
  desc_path <- reader::find.file("DESCRIPTION", dir = "", dirs = sib_dirs)
  root_path <- dirname(desc_path)
  result <- paste(root_path, fp, sep='/')
  return(result)
}

find_path <- function(fp) {
  result <- tryCatch(rprojroot::find_root_file(fp, criterion = 
                                        rprojroot::is_r_package | 
                                        rprojroot::is_rstudio_project ),
                     error=function(cond) {
                       testpath <- find_test_path(fp)
                       return(testpath)
                     })
  return(result)
}

is_check_mode <- function() {
  result <- tryCatch({
    rprojroot::find_root_file('.',
                              criterion =
                                rprojroot::is_r_package |
                                rprojroot::is_rstudio_project)
    return(FALSE)
  },
  error=function(cond) {
    return(TRUE)
  })
  return(result)
}

is_skip_mode <- function() {
  return(is_check_mode())
}


touch_path <- function(fp) {
  fn <- find_path(fp)
  system2("touch", args=c(fn))
  return(fn)
}

getwd_base <- function() {
  result <- find_path("")
  return(result)
}


setwd_base <- function() {
  result <- getwd()
  base_wd <- getwd_base()
  setwd(base_wd)
  return(result)
}

# ---(io helper functions)---------------------------------------------

io_path <- function(path, name="", create_path=TRUE) {
  basename <- find_path(path)
  if (nchar(name) > 0) {
    result <- paste(basename, name, sep='/')
  } else {
    result <- basename
  }
  if (create_path) {
    ensure_path(result)
  }
  return(result)
}

io_data <- function(path = "", name = "", base = fn_base(),
                    kind = "def", mode = "ext", create_path = TRUE) {
  full <- paste(fn_exdata(), mode, paste(base, kind, sep = "."), sep = "/")
  if (nchar(path) > 0) {
    full <- paste(full, path, sep = "/")
  }
  if (nchar(name) > 0) {
    full <- paste(full, name, sep = "/")
  }
  result <- io_path(full, create_path = create_path)
  return(result)
}

io_temp <- function(path = "", name = "", create_path = TRUE) {
  full <- paste(fn_temp(), sep = "/")
  if (nchar(path) > 0) {
    full <- paste(full, path, sep = "/")
  }
  if (nchar(name) > 0) {
    full <- paste(full, name, sep = "/")
  }
  result <- io_path(full, create_path = create_path)
  return(result)
}

io_logs <- function(path = "", name = "", create_path = TRUE) {
  full <- paste(fn_logs(), sep = "/")
  if (nchar(path) > 0) {
    full <- paste(full, path, sep = "/")
  }
  if (nchar(name) > 0) {
    full <- paste(full, name, sep = "/")
  }
  result <- io_path(full, create_path=create_path)
  return(result)
}

io_exec <- function(path = "", name = "", create_path = FALSE) {
  result <- NULL
  if (file.exists(name)) {
    result <- name
  } else {
    full <- paste(fn_exec(), sep = "/")
    if (nchar(path) > 0) {
      full <- paste(full, path, sep = "/")
    }
    if (nchar(name) > 0) {
      full <- paste(full, name, sep = "/")
    }
    result <- io_path(full, create_path = create_path)
  }
  return(result)
}

# ---(`target` wrapprs)---------------------------------------------

## convert filename to filedescriptor with access timestamp
##
## @param fn String filename
## @return fd
## @export
as.IOfd <- function(fn) {
  tm <- Sys.time()
  ts <- strftime(tm, "%Y-%m-%dT%H:%M:%S%z", usetz = TRUE)
  fd <- structure(list(fn = fn, tm = tm, ts = ts, class = "IOfd"))
  return(fd)
}

## extract filename from filedesciptor
##
## @param fd IOfd descriptor
## @return fn
## @export
as.IOfn <- function(fd) {
  fn <- fd$fn
  return(fn)
}
