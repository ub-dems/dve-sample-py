/*
 * Package: dvesimpler
 * File: dummy_mean.cpp
 * Author: datalab
 * Description: Simple Demo C++ source file with Rcpp
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Seealso: ../notes/howtos/Rcpp-HOWTO-claude-v4.md
 * Seealso: ../src/dummy-stats.cpp
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
#include <numeric>
// #include <random>
// #include <stdexcept>
// #include <string>
// #include <vector>


// Use namespaces
using namespace Rcpp;
using namespace std;


double dmy_mean_v0(NumericVector xs) {
  int n = xs.size();
  double total = 0;
   
  for(int i = 0; i < n; ++i) {
    total += xs[i];
  }
    
  return total / n;
}
 
double dmy_mean_v1(NumericVector xs) {
  int n = xs.size();
  double total = 0;
   
  NumericVector::iterator it;
  for(it = xs.begin(); it != xs.end(); ++it) {
    total += *it;
  }  
  return total / n;
}
 
double dmy_mean_v2(NumericVector xs) {
  int n = xs.size();
  return std::accumulate(xs.begin(), xs.end(), 0.0) / n;
}

double dmy_mean_v3(NumericVector xs) {
  int n = xs.size();
  double total = 0;
   
  for(const auto &x : xs) {
    total += x;
  }   
  return total / n;
}
 
// [[Rcpp::export]]
Rcpp::NumericVector dmy_mean(NumericVector xs) {
  double result = dmy_mean_v3(xs);
  return Rcpp::NumericVector::create(result); 
}
 
 
 
/*** R
     library(microbenchmark)
     x <- runif(1e5)
     microbenchmark(
     mean(x),
     dmy_mean(x)
     )
*/

