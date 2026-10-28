// Rcpp Performance Benchmark Examples
// Copyright (C) 2025 Author Name
// 
// This file is part of the Rcpp ecosystem performance optimization examples.
// Licensed under GPL (>= 2)

// {{Rcpp::plugins(cpp17)}}   // unused, only for Rcpp::sourceCpp()
// {{Rcpp::plugins(openmp)}}  // unused, only for Rcpp::sourceCpp()

// [[Rcpp::depends(RcppArmadillo)]]

#include <RcppArmadillo.h>
#include <set>
#include <string>
#include <sstream>

#ifdef _OPENMP
#include <omp.h>
#else
#error "_OPENMP undefined"
#endif

using namespace Rcpp;
using namespace arma;

//==============================================================================
// Logging Support Functions
//==============================================================================

static int log_level = 0;
static std::set<std::string> trace_locations;

//' Set logging verbosity level
//' @param level Integer verbosity level (0=info, 3=trace)
//' @export
// [[Rcpp::export]]
void dmy_pf_log_set_level(int level) {
  log_level = level;
}

//' Get current logging level
//' @return Current verbosity level
//' @export
// [[Rcpp::export]]
int dmy_pf_log_get_level() {
  return log_level;
}

//' Reset trace location tracking
//' @export
// [[Rcpp::export]]
void dmy_pf_log_reset() {
  trace_locations.clear();
}

//' Output log message if verbosity >= 0
//' @param file Source file name
//' @param line Line number  
//' @param message Log message
//' @export
// [[Rcpp::export]]
void dmy_pf_log_out(const std::string& file, int line, 
                    const std::string& message) {
  if (log_level >= 0) {
    Rcpp::Rcout << "[LOG] " << file << ":" << line << " " << message << std::endl;
  }
}

//' Output trace message if verbosity >= 3 (once per location)
//' @param file Source file name
//' @param line Line number
//' @param message Trace message  
//' @export
// [[Rcpp::export]]
void dmy_pf_log_trace(const std::string& file, int line,
                      const std::string& message) {
  if (log_level >= 3) {
    std::stringstream ss;
    ss << file << ":" << line;
    std::string location = ss.str();
    
    if (trace_locations.find(location) == trace_locations.end()) {
      trace_locations.insert(location);
      Rcpp::Rcerr << "[TRACE] " << location << " " << message << std::endl;
    }
  }
}

#define V_LOG(msg) dmy_pf_log_out(__FILE__, __LINE__, msg)
#define V_TRACE(msg) dmy_pf_log_trace(__FILE__, __LINE__, msg)

//==============================================================================
// Sum Function Group - Various Implementation Strategies  
//==============================================================================

//' Sum using C-style for loop with manual indexing
//' @param x Numeric vector to sum
//' @return Sum of vector elements
//' @examples
//' \dontrun{
//' x <- rnorm(1000)
//' result <- dmy_pf_sum_c_style(x)
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_c_style(const NumericVector& x) {
  V_TRACE("C-style sum starting");
  double sum = 0.0;
  int n = x.size();
  
  for (int i = 0; i < n; ++i) {
    sum += x[i];
  }
  
  V_TRACE("C-style sum completed");
  return sum;
}

//' Sum using C++11 range-based for loop
//' @param x Numeric vector to sum  
//' @return Sum of vector elements
//' @examples
//' \dontrun{
//' x <- rnorm(1000)
//' result <- dmy_pf_sum_cpp_range(x)
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_cpp_range(const NumericVector& x) {
  V_TRACE("C++ range-based sum starting");
  double sum = 0.0;
  
  for (const double& val : x) {
    sum += val;
  }
  
  V_TRACE("C++ range-based sum completed");
  return sum;
}

//' Sum using STL iterators
//' @param x Numeric vector to sum
//' @return Sum of vector elements  
//' @examples
//' \dontrun{
//' x <- rnorm(1000)
//' result <- dmy_pf_sum_stl_iter(x)
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_stl_iter(const NumericVector& x) {
  V_TRACE("STL iterator sum starting");
  double sum = std::accumulate(x.begin(), x.end(), 0.0);
  V_TRACE("STL iterator sum completed");
  return sum;
}

#ifdef _OPENMP
//' Sum using OpenMP parallel reduction
//' @param x Numeric vector to sum
//' @return Sum of vector elements
//' @examples  
//' \dontrun{
//' x <- rnorm(10000)
//' result <- dmy_pf_sum_omp_parallel(x)
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_omp_parallel(const NumericVector& x) {
  V_TRACE("OpenMP parallel sum starting");
  double sum = 0.0;
  int n = x.size();
  
  #pragma omp parallel for reduction(+:sum)
  for (int i = 0; i < n; ++i) {
    sum += x[i];
  }
  
  V_TRACE("OpenMP parallel sum completed");
  return sum;
}

//' Sum using OpenMP parallel for with SIMD vectorization
//' @param x Numeric vector to sum
//' @return Sum of vector elements
//' @examples
//' \dontrun{
//' x <- rnorm(10000)  
//' result <- dmy_pf_sum_omp_simd(x)
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_omp_simd(const NumericVector& x) {
  V_TRACE("OpenMP SIMD sum starting");
  double sum = 0.0;
  int n = x.size();
  
  #pragma omp parallel for simd reduction(+:sum)
  for (int i = 0; i < n; ++i) {
    sum += x[i];
  }
  
  V_TRACE("OpenMP SIMD sum completed");
  return sum;
}
#endif

//' Sum using RcppArmadillo
//' @param x Numeric vector to sum
//' @return Sum of vector elements
//' @examples
//' \dontrun{
//' x <- rnorm(1000)
//' result <- dmy_pf_sum_armadillo(x)  
//' }
//' @export
// [[Rcpp::export]]
double dmy_pf_sum_armadillo(const NumericVector& x) {
  V_TRACE("Armadillo sum starting");
  arma::vec av = as<arma::vec>(x);
  double result = arma::accu(av);
  V_TRACE("Armadillo sum completed");
  return result;
}

//' Sum using R base::sum function called from C++
//' @param x Numeric vector to sum
//' @return Sum of vector elements
//' @examples
//' \dontrun{
//' x <- rnorm(1000)
//' result <- dmy_pf_sum_r_base(x)
//' }
//' @export  
// [[Rcpp::export]]
double dmy_pf_sum_r_base(const NumericVector& x) {
  V_TRACE("base::sum starting");
  Function sum("sum");
  NumericVector result = sum(x);
  V_TRACE("base::sum completed");
  return result[0];
}

//==============================================================================
// Outer Product Function Group - Matrix Operations
//==============================================================================

//' Outer product using C-style nested loops
//' @param x First input vector
//' @param y Second input vector  
//' @return Matrix representing outer product
//' @examples
//' \dontrun{
//' x <- rnorm(100)
//' y <- rnorm(100)
//' result <- dmy_pf_outer_c_style(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_c_style(const NumericVector& x, 
                                   const NumericVector& y) {
  V_TRACE("C-style outer product starting");
  int nx = x.size();
  int ny = y.size();
  NumericMatrix result(nx, ny);
  
  for (int i = 0; i < nx; ++i) {
    for (int j = 0; j < ny; ++j) {
      result(i, j) = x[i] * y[j];
    }
  }
  
  V_TRACE("C-style outer product completed");
  return result;
}

//' Outer product using C++ STL iterators
//' @param x First input vector
//' @param y Second input vector
//' @return Matrix representing outer product  
//' @examples
//' \dontrun{
//' x <- rnorm(100)
//' y <- rnorm(100)
//' result <- dmy_pf_outer_cpp_iter(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_cpp_iter(const NumericVector& x,
                                    const NumericVector& y) {
  V_TRACE("C++ iterator outer product starting");
  int nx = x.size();
  int ny = y.size(); 
  NumericMatrix result(nx, ny);
  
  int i = 0;
  for (auto it_x = x.begin(); it_x != x.end(); ++it_x, ++i) {
    int j = 0;
    for (auto it_y = y.begin(); it_y != y.end(); ++it_y, ++j) {
      result(i, j) = (*it_x) * (*it_y);
    }
  }
  
  V_TRACE("C++ iterator outer product completed");
  return result;
}

#ifdef _OPENMP  
//' Outer product using OpenMP collapsed parallel loops
//' @param x First input vector
//' @param y Second input vector
//' @return Matrix representing outer product
//' @examples
//' \dontrun{
//' x <- rnorm(500)
//' y <- rnorm(500)  
//' result <- dmy_pf_outer_omp_collapse(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_omp_collapse(const NumericVector& x,
                                        const NumericVector& y) {
  V_TRACE("OpenMP collapsed outer product starting");
  int nx = x.size();
  int ny = y.size();
  NumericMatrix result(nx, ny);
  
  #pragma omp parallel for collapse(2)
  for (int i = 0; i < nx; ++i) {
    for (int j = 0; j < ny; ++j) {
      result(i, j) = x[i] * y[j];
    }
  }
  
  V_TRACE("OpenMP collapsed outer product completed");
  return result;
}

//' Outer product using OpenMP parallel outer loop with SIMD inner loop
//' @param x First input vector  
//' @param y Second input vector
//' @return Matrix representing outer product
//' @examples
//' \dontrun{
//' x <- rnorm(500)
//' y <- rnorm(500)
//' result <- dmy_pf_outer_omp_simd(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_omp_simd(const NumericVector& x,
                                    const NumericVector& y) {
  V_TRACE("OpenMP SIMD outer product starting");
  int nx = x.size();
  int ny = y.size();
  NumericMatrix result(nx, ny);
  
  #pragma omp parallel for
  for (int i = 0; i < nx; ++i) {
    #pragma omp simd
    for (int j = 0; j < ny; ++j) {
      result(i, j) = x[i] * y[j];
    }
  }
  
  V_TRACE("OpenMP SIMD outer product completed");
  return result;
}
#endif

//' Outer product using RcppArmadillo
//' @param x First input vector
//' @param y Second input vector
//' @return Matrix representing outer product
//' @examples
//' \dontrun{
//' x <- rnorm(100)
//' y <- rnorm(100)
//' result <- dmy_pf_outer_armadillo(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_armadillo(const NumericVector& x,
                                     const NumericVector& y) {
  V_TRACE("Armadillo outer product starting");
  arma::vec ax = as<arma::vec>(x);
  arma::vec ay = as<arma::vec>(y);
  arma::mat result = ax * ay.t();
  V_TRACE("Armadillo outer product completed");
  return wrap(result);
}

//' Outer product using R base::outer function called from C++
//' @param x First input vector
//' @param y Second input vector  
//' @return Matrix representing outer product
//' @examples
//' \dontrun{
//' x <- rnorm(100)
//' y <- rnorm(100)
//' result <- dmy_pf_outer_r_base(x, y)
//' }
//' @export
// [[Rcpp::export]]
NumericMatrix dmy_pf_outer_r_base(const NumericVector& x,
                                  const NumericVector& y) {
  V_TRACE("base::outer starting");
  Function outer("outer");
  NumericMatrix result = outer(x, y, "*");
  V_TRACE("base::outer completed");
  return result;
}
