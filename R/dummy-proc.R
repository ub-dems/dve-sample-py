##
# sample reader script functions, referenced in _targets.R pipeline
#

#' @include dummy-path.R
NULL


dmy_p01_args_default <- list(
  options <- list(
    show_data <- TRUE,
    plot_data <- TRUE
  ),
  args <- c(
    "aaa"
  )
)

dmy_p01_run_args <- dmy_p01_args_default

dmy_p01_args_set <- function(args = dmy_p01_args_default) {
  result <- dmy_p01_run_args
  if (args != NULL) {
    dmy_p01_run_args <- args
  } else {
    dmy_p01_run_args <- dmy_p01_args_default
  }
  result
}

dmy_p01_args <- \() dmy_p01_run_args



#' chck compressed input file
#'
#' @return fd
#' @export
dmy_p01_list_zip_share_data <- function (){
  fn <- dmy_fn_net_pjme_hourly_z()
  loginfo("# list_zip: %s", fn)
  fs <- file.info(fn)
  head(fs)
  as.IOfd(fn)
}


#' load 3y pjme hourly data (def)
#'
#' @param fn String filtered pjme_hourly file name
#' @return pjme_hourly_3y
#' @export
dmy_p01_load_user_private_data <- function(fn = dmy_fn_def_pjme_hourly_3y()) {
  loginfo("# read_csv: %s", fn)
  pjme_hourly_3y <- readr::read_csv(fn, show_col_types = FALSE);
  pjme_hourly_3y
}

#' filter and save 3y pjme hourly data (def)
#'
#' @param pjme_hourly dataframe unfiltered pjme hourly data
#' @param from_date String starting date in "yyyy-mm-dd" string format
#' @param to_date String ending date in "yyyy-mm-dd" string format
#' @return pjme_hourly_3y
#' @export
dmy_p01_save_user_private_data <- function(pjme_hourly, from_date, to_date) {
  start_dt <- as.Date(from_date)
  end_dt <- as.Date(to_date)

  pjme_hourly_3y_tmp <- pjme_hourly |>
    dplyr::mutate(Date_only = as.Date(.data$Datetime)) |>
    dplyr::filter(.data$Date_only >= start_dt, .data$Date_only < end_dt)

  fn <- dmy_fn_def_pjme_hourly_3y()
  loginfo("# write_csv: %s", fn)
  readr::write_csv(pjme_hourly_3y_tmp, fn)
  as.IOfd(fn)
}

#' test compressed unfiltered pjme hourly data (net)
#'
#' @return fd_net_pjme_hourly_z
#' @export
dmy_p01_test_zip_share_data <- function() {
  fz <- dmy_fn_net_pjme_hourly_z()
  loginfo("# check: %s", fz)
  if (!file.exists(fz)) {
    logerror("# missing: %s", fz)
    return(as.IOfd(fz))
  }
  as.IOfd(fz)
}

#' copy compressed unfiltered pjme hourly data (net)
#' to uncompressed unfiltered pjme hourly data (loc)
#'
#' @param fz String compressed pjme_hourly file name
#' @return fn_net_pjme_hourly
#' @export
dmy_p01_copy_zip_share_data <- function (fz = dmy_fn_net_pjme_hourly_z()){
  fn <- dmy_fn_loc_pjme_hourly()
  if (!file.exists(fn)) {
    loginfo("# existing: %s", fn)
    return (as.IOfd(fn))
  }
  loginfo("# read_csv: %s", fz)
  pjme_hourly_z <- readr::read_csv(fz,
    col_types = readr::cols(
      Datetime = readr::col_datetime(format = "%Y-%m-%d %H:%M:%S")
    ),
    show_col_types = FALSE
  )
  pjme_hourly_z$Datetime <- format(pjme_hourly_z$Datetime,
                                   format = "%Y-%m-%d %H:%M:%S")
  loginfo("# write_csv: %s", fn)
  readr::write_csv(pjme_hourly_z, fn)
  as.IOfd(fn)
}

#' copy compressed unfiltered pjme hourly data (net)
#' to uncompressed unfiltered pjme hourly data (loc)
#'
#' @param fn String uncompressed pjme_hourly file name
#' @return pjme_hourly dataframe
#' @export
dmy_p01_load_host_local_data <- function(fn = dmy_fn_loc_pjme_hourly()){
  loginfo("# read_csv: %s", fn)

  pjme_hourly <- readr::read_csv(fn,
    col_types = readr::cols(
      Datetime = readr::col_datetime(
        format = "%Y-%m-%d %H:%M:%S"
      )
    ),
    show_col_types = FALSE
  )

  pjme_hourly
}

dmy_p01_view_user_private_data <- function (pjme_hourly_3y) {
  if (dmy_p01_args()$options$show_data) {
    View(pjme_hourly_3y)
  }
  0
}

#' show unfiltered pjme hourly data
#'
#' @param pjme_hourly dataframe unfiltered pjme hourly data
#' @return void
#' @export
dmy_p01_view_host_local_data <- function(pjme_hourly) {
  if (dmy_p01_args()$options$show_data) {
    View(pjme_hourly)
  }
  0
}

#' show 3y pjme hourly data
#'
#' @param pjme_hourly_3y dataframe 3y pjme hourly data
#' @return void
#' @export
dmy_p01_show_user_private_data <- function (pjme_hourly_3y){
  fn <- dmy_fn_txt_pjme_hourly_3y()
  df <- pjme_hourly_3y
  loginfo("# report: %s", fn)
  out <- out_capture(summary(df))
  cat(out, file = fn)
  as.IOfd(fn)
}

#' show pjme hourly data
#'
#' @param pjme_hourly dataframe unfiltered pjme hourly data
#' @return void
#' @export
dmy_p01_show_host_local_data <- function (pjme_hourly){
  fn <- dmy_fn_txt_pjme_hourly()
  df <- pjme_hourly
  loginfo("# report: %s", fn)
  out <- out_capture(summary(df))
  cat(out, file = fn)
  as.IOfd(fn)
}

#' plot 3y pjme hourly data
#'
#' @param pjme_hourly_3y dataframe unfiltered pjme hourly data
#' @return void
#' @export
dmy_p01_plot_user_private_data <- function (pjme_hourly_3y){

  fn <- dmy_fn_tmp_pjme_hourly_3y()

  if (!dmy_p01_args()$options$plot_data) {
    logwarn("# plot: %s, skipped", fn)
    return(as.IOfd(fn))
  }

  df <- pjme_hourly_3y
  loginfo("# plot: %s", fn)

  pdf(fn)
  graphics::symbols(df$Datetime, df$pjme_MW)
  dev.off()

  as.IOfd(fn)
}

#' plot unfiltered pjme hourly data
#'
#' @param pjme_hourly dataframe unfiltered pjme hourly data
#' @return void
#' @export
dmy_p01_plot_host_local_data <- function (pjme_hourly){

  fn <- dmy_fn_tmp_pjme_hourly()

  if (!dmy_p01_args()$options$plot_data) {
    logwarn("# plot: %s, skipped", fn)
    return(as.IOfd(fn))
  }

  df <- pjme_hourly
  loginfo("# plot: %s", fn)

  pdf(fn)
  graphics::symbols(df$Datetime, df$pjme_MW)
  dev.off()

  as.IOfd(fn)
}




#' pjme hourly data ELT pipeline
#'
#' @param args (optparse) parsed args structure
#' @return void
#' @export
dmy_p01_task <- function(args = NULL) {

  dmy_p01_args_set(args)

  loginfo("#> extract, ...")
  fd_net_pjme_hourly_z <- dmy_p01_list_zip_share_data()
  fd_net_pjme_hourly <- dmy_p01_copy_zip_share_data(fd_net_pjme_hourly_z$fn)
  pjme_hourly <- dmy_p01_load_host_local_data(fd_net_pjme_hourly$fn)
  fd_def_pjme_hourly_3y <- dmy_p01_save_user_private_data(pjme_hourly,
                               from_date = "2016-01-01", to_date = "2019-01-01")
  loginfo("#< extract, done")
  loginfo("#> load, ...")
  pjme_hourly_3y <- dmy_p01_load_user_private_data(fd_def_pjme_hourly_3y$fn)
  loginfo("#> load, done.")
  loginfo("#> transform, ...")
  fd_txt_pjme_hourly <- dmy_p01_show_host_local_data(pjme_hourly)
  fd_tmp_pjme_hourly <- dmy_p01_plot_host_local_data(pjme_hourly)
  fd_txt_pjme_hourly_3y <- dmy_p01_show_user_private_data(pjme_hourly_3y)
  fd_tmp_pjme_hourly_3y <- dmy_p01_plot_user_private_data(pjme_hourly_3y)
  loginfo("#< transform,done.")
  fn <- touch_path(dmy_fn_sts_p01_proc_main())
  loginfo("# mark: %s", fn)
  as.IOfd(fn)
}

#' pjme hourly data ELT process entry point
#'
#' @param args (optparse) parsed args structure
#' @return rc
#' @export
dmy_p01_main <- function(args = NULL) { 
  loginfo("#> start: %s", paste(args, sep = " "))
  dmy_p01_task(args) # ignore return for forced execution
  fn <- touch_path(dmy_fn_sts_p01_proc_main())
  loginfo("# mark: %s", fn)
  rc_get()
}
