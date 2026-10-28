/*
 * Package: dvesimpler
 * File: dummy_arma.cpp
 * Author: datalab@unimib.it
 * Description: Demo C++ source file with RcppArmadillo
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Seealso: ../notes/howtos/Rcpp-HOWTO-Q4-*.md
 * Seealso: ../exec/dummy-rcpp.R
 * Created: 2025
 * License: GPL (>= 2)
 */

// [[Rcpp::interfaces(r,cpp)]]
// Enable C++17 support
// [[Rcpp::plugins(cpp17)]]
// [[Rcpp::plugins(openmp)]]

// Declare dependencies
// [[Rcpp::depends(RcppArmadillo)]]


// static config
#include "config.h"

// Rcpp dependencies
#include <RcppArmadillo.h>
#include <Rcpp.h>

#ifdef _OPENMP
#include <omp.h>
#endif


// Standard library headers
// #include <algorithm>
// #include <cmath>
// #include <exception>
// #include <functional>
// #include <iterator>
// #include <limits>
// #include <memory>
// #include <numeric>
// #include <random>
// #include <stdexcept>
// #include <string>
// #include <vector>

// Package Public Functions

#include <dvesimpler.h>

// Package Private Functions

#include "dummy_eigen.h"

// Use namespaces
using namespace Rcpp;
using namespace std;

/*
  using namespace arma;
*/

/*
 * =============================================================================
 * LINEAR ALGEBRA WITH RcppArmadillo
 * =============================================================================
 */

//' Matrix Multiplication with RcppArmadillo
//'
//' Performs (parallel) matrix multiplication efficiently in C++.
//'
//' @param A an arma::mat matrix
//' @param B an arma::mat matrix (with rows(B) = cols(A))
//'
//' @return Matrix Product as arma::mat matrix
//'
//' @export
// [[Rcpp::export]]
arma::mat dmy_arma_matrix_mult(const arma::mat& A, const arma::mat& B) {
    // Check dimensions
    if (A.n_cols != B.n_rows) {
        stop("Incompatible matrix dimensions");
    }
    
    // Efficient matrix multiplication
    return A * B;
}

//' Eigen decomposition of dense symmetric/hermitian matrix with RcppArmadillo
//'
//' Performs (parallel) eigenvalues decomposition efficiently in C++.
//'
//' @param X an arma::mat square matrix
//'
//' @return A named list with eigenvaluues and eigenvectors (as arma types)
//'
//' @export
// [[Rcpp::export]]
Rcpp::List dmy_arma_eigsym(const arma::mat& X) {
    arma::vec eigenvalues;
    arma::mat eigenvectors;
    
    bool success = arma::eig_sym(eigenvalues, eigenvectors, X);
    
    if (!success) {
        stop("Eigenvalue decomposition failed");
    }
    
    return List::create(
        Named("values") = eigenvalues,
        Named("vectors") = eigenvectors
    );
}


/*
 * =============================================================================
 * LINEAR ALGEBRA WITH RcppEigen
 * =============================================================================
 */

// RcppEigen wrappers
// Seealso: ../notes/howtos/Rcpp-HOWTO-Q4-*.md#A4.2


//' Check GSL Build Configuration.
//'
//' Returns definition of HAVE_EIGEN macro from "config.h".
//'
//' @return EIGEN linkage support
//'
//' @export
// [[Rcpp::export]]
bool dmy_eigen_is_enabled() {
  return dmy_core_is_eigen_enabled();
}


//' Matrix Multiplication with Transpose with RcppEigen
//'
//' Performs parallel Gram matrix \eqn{A^T * A}  computation efficiently in C++.
//'
//' @param A an Eigen matrix
//'
//' @return The prodoct of transposed matrix with itsself as Eigen Matrix
//'
//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix dmy_gram_matrix_eigen(const Rcpp::NumericMatrix& A) {
  return dmy_core_gram_matrix_eigen(A);
}


//' Linear Regression with RcppEigen
//'
//' Compute (parallel) linear regression via QR decomposition efficiently in C++.
//'
//' @param X an Eigen matrix
//' @param y an Eigen vector
//'
//' @return A Named list with linear regression coefficients and residuals
//'
//' @export
// [[Rcpp::export]]
Rcpp::List dmy_linear_regression_eigen(const Rcpp::NumericMatrix& X,
                             const Rcpp::NumericVector& y) {
  return dmy_core_linear_regression_eigen(X,y);
}


