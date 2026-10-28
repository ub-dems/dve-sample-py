##
# sample reader script functions: data pathnames
#

dmy_fn_path  <- \() "examples/kaggle-pjm"

dmy_dd_def <- \(name) def_path(path = dmy_fn_path(), name = name)
dmy_dd_loc <- \(name) loc_path(path = dmy_fn_path(), name = name)
dmy_dd_net <- \(name) net_path(path = dmy_fn_path(), name = name)

dmy_dd_tmp <- \(name) tmp_path(name = name)
dmy_dd_log <- \(name) log_path(name = name)

dmy_dd_out <- dmy_dd_net


dmy_fn_net_pjme_hourly_z  <- \() dmy_dd_net("zip/PJME_hourly.csv.zip")
dmy_fn_loc_pjme_hourly    <- \() dmy_dd_loc("raw/PJME_hourly.csv")
dmy_fn_def_pjme_hourly_3y <- \() dmy_dd_def("raw/PJME_hourly-3y.csv")

dmy_fn_tmp_pjme_hourly    <- \() dmy_dd_tmp("PJME_hourly.pdf")
dmy_fn_tmp_pjme_hourly_3y <- \() dmy_dd_tmp("PJME_hourly-3y.pdf")

dmy_fn_txt_pjme_hourly    <- \() dmy_dd_tmp("PJME_hourly.txt")
dmy_fn_txt_pjme_hourly_3y <- \() dmy_dd_tmp("PJME_hourly-3y.txt")


dmy_fn_sts_p01_proc_task  <- \() dmy_dd_tmp("dmy_p01_task.sts")
dmy_fn_sts_p01_proc_main  <- \() dmy_dd_tmp("dmy_p01_main.sts")
