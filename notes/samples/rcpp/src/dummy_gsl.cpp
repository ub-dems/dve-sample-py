/*
 * Package: dvesimpler
 * File: dummy_gsl.cpp
 * Author: datalab@unimib.it
 * Description: Demo C++ source file with RcppGSL
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Seealso: ../exec/dummy-rcpp.R
 * Seealso: ../src/config.h
 * Seealso: ../src/Makevars
 * Seealso: ../R/dvesimpler-package.r
 * Seealso: ../DESCRIPTION
 * Created: 2025
 * License: GPL (>= 2)
 */

// [[Rcpp::interfaces(r,cpp)]]
// Enable C++17 support
// [[Rcpp::plugins(cpp17)]]
// [[Rcpp::plugins(openmp)]]

// Declare dependencies
// [[Rcpp::depends(RcppArmadillo)]]
// [[Rcpp::depends(RcppGSL)]]

// static config

#include "config.h"

// Rcpp dependencies
#include <RcppArmadillo.h>
#include <Rcpp.h>

#ifdef _OPENMP
#include <omp.h>
#endif


#ifdef HAVE_GSL
#include <RcppGSL.h>
#endif

#ifdef HAVE_GSL
// GSL headers
#include <gsl/gsl_fit.h>
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_sf_gamma.h>
#include <gsl/gsl_statistics_double.h>
#endif

// Package Public Functions

#include <dvesimpler.h>


// Use namespaces
using namespace Rcpp;
using namespace std;


/*
 * =============================================================================
 * CONDITIONAL GSL LINKAGE
 * =============================================================================
 */

//' @title Check GSL Build Configuration.
//' @description Returns definition of HAVE_GSL macro from "config.h".
//' @return GSL linkage support
//' @examples
//' \dontrun{
//' if (dmy_gsl_is_enabled()) {
//'    a <- c(1/2, 1, 3/2, 2)
//'    b <- c(1/2, 1, 3/2, 2)
//'    beta <- dmy_gsl_beta(a,b)
//'    print(beta)
//' } else {
//'    warning("GSL Support is not enabled")
//' }
//' }
//' @export
// [[Rcpp::export]]
bool dmy_gsl_is_enabled() {
#ifdef HAVE_GSL
  return true; 
#else
  return false; 
#endif
}


namespace {  // Anonymous namespace for internal functions

#ifdef HAVE_GSL
inline double lib_gsl_sf_beta(double a, double b) {
  return gsl_sf_beta(a, b);
}
#else
inline double lib_gsl_sf_beta(double a, double b) {
  Rcpp::stop("Unsupported Operation: GSL support not enabled in dmy_gsl_beta");
}
#endif

} // end anonymous namespace


/*
 * =============================================================================
 * PUBLIC GSL BASED FUNCTIONS
 * =============================================================================
 */

//' @title Calculate vectorized Beta function
//' @description This function calculates Beta function with GSL library.
//' @param a A NumericVector of Beta first argument (a)
//' @param b A NumericVector of Beta second argument (b)
//' @return A NumericVector of Beta(a,b)
//' @examples
//' \dontrun{
//' a <- c(1/2, 1, 3/2, 2)
//' b <- c(1/2, 1, 3/2, 2)
//' beta <- dmy_gsl_beta(a,b)
//' print(beta)
//' }
//' @export
// [[Rcpp::export]]
NumericVector dmy_gsl_beta(NumericVector a, NumericVector b) {
  if (a.size() != b.size()) {
     Rcpp::warning("Input vector size does not match, returning NaN.");
     return Rcpp::NumericVector::create(R_NaN);
  }
  int n = a.size();
  NumericVector result(n);
#ifdef _OPENMP
  #pragma omp parallel for simd
#endif
  for(int i = 0; i < n; ++i) {
     result[i] =  lib_gsl_sf_beta(a[i], b[i]);
  }
  return result; 
}


