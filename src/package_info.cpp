/*
 * Package: dvesimpler
 * File: package_info.cpp
 * Author: datalab
 * Description: Package Initializer and Descriptor
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Seealso: ../notes/howtos/Rcpp-HOWTO-claude-v4.md
 * Seealso: ../src/dummy-mean.cpp
 * Seealso: ../src/dvesimpler.h
 * Seealso: ../exec/dummy-rcpp.R
 * Seealso: ../src/Makevars
 * Seealso: ../R/dvesimpler-package.r
 * Seealso: ../DESCRIPTION
 * Created: 2025
 * License: GPL (>= 2)
 */

// Enable C++17 support
// [[Rcpp::plugins(cpp17)]]

// Declare dependencies

// Rcpp dependencies
#include <RcppArmadillo.h>
#include <Rcpp.h>


// Package Public Functions

#include <dvesimpler.h>


/*
 * =============================================================================
 * PACKAGE INITIALIZATION AND CLEANUP
 * =============================================================================
 */

#define _TRACE_INIT_ 0

// [[Rcpp::init]]
void package_init(DllInfo *dll) {
#if _TRACE_INIT_
  Rcpp::Rcerr << "__package loaded: 'dvsimpler.so'" << std::endl;
#endif
}


// [[Rcpp::export]]
Rcpp::List package_info() {
  return Rcpp::List::create(
      Rcpp::Named("package") = "dvesimpler",
      Rcpp::Named("rcpp_version") = "1.1.0",
      Rcpp::Named("armadillo_version") = "14.6.0-1",
      Rcpp::Named("eigen_version") = "3.4.0",
      Rcpp::Named("cpp_standard") = "C++11",
      Rcpp::Named("compiled") = "2025/08/25" " " "00:00:00 UTC"
                      );
}
