#ifndef dvesimpler_dummy_eigen_H
#define dvesimpler_dummy_eigen_H

// Rcpp dependencies
#include <Rcpp.h>

bool dmy_core_is_eigen_enabled();
Rcpp::NumericMatrix dmy_core_gram_matrix_eigen(const Rcpp::NumericMatrix& A);
Rcpp::List dmy_core_linear_regression_eigen(const Rcpp::NumericMatrix& X,
                                       const Rcpp::NumericVector& y);
#endif // dvesimpler_dummy_eigen_H

