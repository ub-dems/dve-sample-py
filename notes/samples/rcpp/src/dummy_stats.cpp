/*
 * Package: dvesimpler
 * File: dummy_stats.cpp
 * Author: datalab@unimib.it
 * Description: Demo C++ source file with Rcpp
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Seealso: ../src/dummy-mean.cpp
 * Seealso: ../inst/include/dvesimpler.h
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



// static config
#include "config.h"

// Rcpp dependencies
#include <RcppArmadillo.h>
#include <Rcpp.h>

#ifdef _OPENMP
#include <omp.h>
#endif


// Standard library headers
#include <algorithm>
#include <cmath>
#include <exception>
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

// Package Internal Functions

#include "dummy_mean.h"

// Use namespaces
using namespace Rcpp;
using namespace std;


/*
 * =============================================================================
 * UTILITY FUNCTIONS (NOT EXPORTED)
 * =============================================================================
 */

namespace {  // Anonymous namespace for internal functions

// Input validation helper
void validate_input(const NumericVector& data, const std::string& param_name) {
  if (data.size() == 0) {
    throw std::invalid_argument(param_name + " cannot be empty");
  }
        
  if (any(is_infinite(data))) {
    throw std::invalid_argument(param_name + " contains infinite values");
  }
}
    
// Safe mathematical operations
double safe_sqrt(double value) {
  if (value < 0) {
    throw std::domain_error("Cannot take square root of negative number");
  }
  return std::sqrt(value);
}

NumericVector safe_divide(NumericVector a, NumericVector b) __attribute__((unused));
NumericVector safe_divide(NumericVector a, NumericVector b) {
  if (a.size() != b.size()) {
    Rcpp::stop("Vectors must be same length");
  }
  
  NumericVector result(a.size());
  for (int i = 0; i < a.size(); ++i) {
    if (b[i] == 0) {
      Rcpp::warning("Division by zero at index %d", i);
      result[i] = NA_REAL;
    } else {
      result[i] = a[i] / b[i];
    }
  }
  return result;
}


  
    
// Memory-efficient matrix operations
template<typename T>
void initialize_matrix(T& matrix, double fill_value = 0.0) {
  std::fill(matrix.begin(), matrix.end(), fill_value);
}

} // end anonymous namespace



/*
 * =============================================================================
 * INTERNAL PACKAGE LINKAGE
 * =============================================================================
 */

//' Calculate Aritmetic Mean 
//'
//' Compute mean directly without C or R library funcions
//' with exported package function
//' See: dummy_mean.cpp
//'
//' @param data A numeric vector
//'
//' @return Arithmetic mean of data
//'
//' @examples
//' \dontrun{
//' data <- rnorm(100)
//' m <- dmy_custom_mean(data)
//' }
//'
//' @export
// [[Rcpp::export]]
Rcpp::NumericVector dmy_custom_mean(Rcpp::NumericVector data) {
  return dmy_mean(data);
}

//' Print Aritmetic Mean 
//'
//' Print mean calling internal package custom_mean
//' calls inline namespace version from Rcpp::compileAttributes()
//' See: inst/include/*.h
//'
//' @param data A numeric vector
//'
//' @return Arithmetic mean of data
//'
//' @examples
//' \dontrun{
//' data <- rnorm(100)
//' m <- dmy_custom_mean(data)
//' }
//'
//' @export
// [[Rcpp::export]]
void dmy_print_mean(Rcpp::NumericVector data) {
  auto mean = dvesimpler::dmy_custom_mean(data);
  Rcpp::Rcout << "Mean: " << mean << endl;
}



/*
 * =============================================================================
 * DATA STATS COMPUTATION FUNCTIONS (R LIBRARY INTEGRATION)
 * =============================================================================
 */

//' Calculate Robust Summary Statistics
//'
//' Computes comprehensive summary statistics for a numeric vector with
//' robust error handling and missing value treatment.
//'
//' @param data A numeric vector
//' @param confidence_level Confidence level for intervals (default: 0.95)
//' @param na_rm Remove NA values (default: TRUE)
//'
//' @return A named list with summary statistics
//'
//' @examples
//' \dontrun{
//' data <- rnorm(100)
//' stats <- dmy_summary_stats(data)
//' }
//'
//' @export
// [[Rcpp::export]]
List dmy_summary_stats(const NumericVector& data,
                       double confidence_level,
                       bool na_rm) {
    
  try {
    // Input validation
    if (confidence_level <= 0 || confidence_level >= 1) {
      stop("confidence_level must be between 0 and 1");
    }
        
    NumericVector xs = na_rm ? na_omit(data) : data;
    validate_input(xs, "data");

    // --( R libs: stats functions )-------------------------------

    // Get R environment
    Environment base("package:base");
    Environment stats("package:stats");
    
    // Call R functions
    Function r_mean = base["mean"];
    Function r_sd = stats["sd"];
    Function r_var = stats["var"];
    Function r_quantile = stats["quantile"];

    // Execute R functions
    double mean_r_val = as<double>(r_mean(xs));
    double var_r_val = as<double>(r_var(xs));
    double sd_r_val = as<double>(r_sd(xs));
    NumericVector quantiles = r_quantile(xs, 
                                         NumericVector::create(0.25, 0.5, 0.75));
        

    // --( C libs: stats functions )-------------------------------

    // Basic statistics
    const auto n = static_cast<double>(xs.size());
    const double mean_val = mean(xs);
    const double var_val = var(xs);
    const double sd_val = safe_sqrt(var_val);
        
    // Confidence interval
    const double alpha = 1.0 - confidence_level;
    const double t_value = R::qt(1.0 - alpha/2.0, n - 1, 1, 0);
    const double margin_error = t_value * sd_val / std::sqrt(n);
        
    // --( named R list result )-------------------------------
    
    return List::create(
        Named("n") = n,
        Named("mean") = mean_r_val,
        Named("variance") = var_r_val,
        Named("sd") = sd_r_val,
        Named("mean.c") = mean_val,
        Named("variance.c") = var_val,
        Named("sd.c") = sd_val,
        Named("ci_lower") = mean_val - margin_error,
        Named("ci_upper") = mean_val + margin_error,
        Named("confidence_level") = confidence_level,
        Named("q25") = quantiles[0],
        Named("median") = quantiles[1],
        Named("q75") = quantiles[2]
            
                        );
        
  } catch (const std::exception& ex) {
    stop("Error in dmy_summary_stats: %s", ex.what());
  }
}

/*
 * =============================================================================
 * DATA STATS COMPUTATION FUNCTIONS (R LIBRARY INTEGRATION)
 * =============================================================================
 */

//' Custom DataFrame Moving Average
//'
//' Parallel vector moving average example in C++.
//'
//' @param x a numeric vector
//' @param width moving average window width
//'
//' @return A vector of moving averages (moviang average window reduced at edges)
//'
//' @seealso [dmy_df_rolling_average()] for single theraded unvectorized version.
//' 
//' @examples
//' \dontrun{
//'
//' library(dplyr)
//' library(Rcpp)
//' 
//' # Assume the package is loaded, making rolling_average available
//' # sourceCpp("src/rolling_average.cpp") # for interactive testing
//' 
//' my_data <- tibble(
//'   group = rep(c("a", "b"), each = 10),
//'   value = rnorm(20)
//' )
//' 
//' my_data %>%
//'   group_by(group) %>%
//'   mutate(rolled_avg = dmy_df_rolling_average(value, n = 3))
//' 
//' }
//'
//' @export
// [[Rcpp::export]]
Rcpp::NumericVector dmy_omp_rolling_average(Rcpp::NumericVector x, int width) {
    int len = x.size();
    Rcpp::NumericVector out(len);

    double s = 0;  // early declaration for pragma reduction
    int n = 0;     // ...
    
  // The pragma tells the compiler to parallelize this loop.
  // The reduction clause handles the `total` variable safely across threads.
#ifdef _OPENMP
// #pragma omp parallel for private(i,j) collapse(2) reduction(+:n, s)
#pragma omp parallel for reduction(+:n, s)
#endif
    for(int i = 0; i < len; ++i) {
        s = 0;
        n = 0;
#ifdef _OPENMP
#pragma omp simd
#endif
        for(int j = std::max(0, i - width + 1); j <= i; ++j) {
            s += x[j];
            n++;
        }
        out[i] = s / n;
    }
    return out;
}

