##
#' @name dvesimpler
#' @description
#' To learn more about dvesimpler, start with the vignettes:
#' `browseVignettes(package = "dvesimpler")`
#' @keywords internal
"_PACKAGE"


## usethis namespace: start
# 
# 
#' @useDynLib dvesimpler, .registration = TRUE
#' @importFrom Rcpp cppFunction
#' @importFrom RcppArmadillo armadillo_get_number_of_omp_threads
#' 
## @importFrom RcppGSL LdFlags CFlags
#
#' @importFrom keras3 config_backend
# 
#' @importFrom foreach foreach
#' @importFrom doParallel registerDoParallel
#' @importFrom parallelly availableCores makeClusterPSOCK
# 
#' @importFrom here here
#' @importFrom logger log_info
#' @importFrom magrittr %>%
#' @importFrom modules module export import
#' @importFrom reticulate py_discover_config
#' @importFrom rprojroot is_r_package is_rstudio_project is_testthat find_root find_root_file
#' @importFrom yaml as.yaml
## @importFrom rzmq subscribe
## @importFrom scriptName current_filename
# 
# 
#' @importFrom tidyverse tidyverse_conflicts
#' @importFrom rlang .data
#' @importFrom glue glue_data
#' @importFrom grDevices pdf dev.off
#' @importFrom readr read_csv write_csv cols col_datetime
#' @importFrom dplyr filter
#' @importFrom utils str capture.output head View packageVersion
#' @importFrom stats runif
## @importFrom argparse ArgumentParser
## @importFrom targets tar_make
## @importFrom ggplot2 ggplot aes geom_line xlab
# 
## usethis namespace: end


utils::globalVariables(c("Datetime","PJME_MW"))


NULL


