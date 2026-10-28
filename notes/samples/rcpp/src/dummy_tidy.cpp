/*
 * Package: dvesimpler
 * File: dummy_tidy.cpp
 * Author: datalab@unimib.it
 * Description: Demo C++ source file for Tidyverse integration
 * Seealso: ../notes/howtos/Rcpp-HOWTO.md
 * Created: 2025
 * License: GPL (>= 2)
 */

// [[Rcpp::interfaces(r,cpp)]]
// Enable C++17 support
// [[Rcpp::plugins(cpp17)]]
// [[Rcpp::plugins(openmp)]]

// Declare dependencies
// [[Rcpp::depends(RcppArmadillo)]]
// [[Rcpp::depends(dplyr)]]


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

// Use namespaces
using namespace Rcpp;
using namespace std;

/*
 * =============================================================================
 * DATA TRANSFORMATION FUNCTIONS
 * =============================================================================
 */

//' Calculate a Summry Dataframme as a sum, by group colun
//'
//' Aggregate by sum value column bt group column
//' 
//' @param df An input dataframme
//' @param group_col keys column name
//' @param value_col values column name
//'
//' @return A two column dataframe with keys and valuue
//'
//' @examples
//' \dontrun{
//' data <- rnorm(100)
//' stats <- dmy_summary_stats(data)
//' }
//'
//' @export
// [[Rcpp::export]]
DataFrame dmy_dplyr_grouped_sum(DataFrame df, String group_col, String value_col) {
  // Extract columns
  CharacterVector groups = df[group_col];
  NumericVector values = df[value_col];
  
  // Create map for grouped sums
  std::unordered_map<std::string, double> group_sums;
  
  for (int i = 0; i < groups.size(); ++i) {
    if (CharacterVector::is_na(groups[i]) || NumericVector::is_na(values[i])) continue;
    
    std::string group = Rcpp::as<std::string>(groups[i]);
    group_sums[group] += values[i];
  }
  
  // Convert back to R vectors
  CharacterVector out_groups(group_sums.size());
  NumericVector out_sums(group_sums.size());
  
  size_t idx = 0;
  for (const auto& pair : group_sums) {
    out_groups[idx] = pair.first;
    out_sums[idx] = pair.second;
    ++idx;
  }
  
  return DataFrame::create(
      Named("group") = out_groups,
      Named("sum") = out_sums
                           );
}

//' Efficient Group Operations
//'
//' Performs group-wise operations on data frames efficiently in C++.
//'
//' @param data Data frame
//' @param group_col Name of the grouping column
//' @param value_col Name of the value column
//' @param operation Operation to perform ("mean", "sum", "count", "sd")
//'
//' @return Data frame with group results
//'
//' @export
// [[Rcpp::export]]
DataFrame dmy_group_op(const DataFrame& data,
                       const std::string& group_col,
                       const std::string& value_col,
                       const std::string& operation) {
    
  try {

    /*      
            Rcpp::Environment dplyr_ns = Rcpp::Environment::namespace_env("dplyr");
            Rcpp::Function mutate = dplyr_ns["mutate"];
    */    
      
    // Extract columns
    CharacterVector groups = data[group_col];
    NumericVector values = data[value_col];
        
    if (groups.size() != values.size()) {
      stop("Group and value columns must have the same length");
    }
        
    // Find unique groups
    CharacterVector unique_groups = unique(groups);
    std::vector<double> results(unique_groups.size());
        
    // Perform group operations
    for (int i = 0; i < unique_groups.size(); ++i) {
      std::string current_group = as<std::string>(unique_groups[i]);
      std::vector<double> group_values;
            
      // Collect values for current group
      for (int j = 0; j < groups.size(); ++j) {
        if (as<std::string>(groups[j]) == current_group) {
          if (!NumericVector::is_na(values[j])) {
            group_values.push_back(values[j]);
          }
        }
      }
            
      // Calculate result based on operation
      if (group_values.empty()) {
        results[i] = NA_REAL;
      } else if (operation == "mean") {
        results[i] = std::accumulate(group_values.begin(), group_values.end(), 0.0) / group_values.size();
      } else if (operation == "sum") {
        results[i] = std::accumulate(group_values.begin(), group_values.end(), 0.0);
      } else if (operation == "count") {
        results[i] = static_cast<double>(group_values.size());
      } else if (operation == "sd") {
        if (group_values.size() < 2) {
          results[i] = NA_REAL;
        } else {
          double mean_val = std::accumulate(group_values.begin(), group_values.end(), 0.0) / group_values.size();
          double sum_sq_diff = 0.0;
          for (double val : group_values) {
            sum_sq_diff += std::pow(val - mean_val, 2);
          }
          results[i] = std::sqrt(sum_sq_diff / (group_values.size() - 1));
        }
      } else {
        stop("Unknown operation: %s", operation.c_str());
      }
    }
        
    return DataFrame::create(
        Named(group_col) = unique_groups,
        Named("result") = NumericVector(results.begin(), results.end())
                             );
        
  } catch (const std::exception& e) {
    stop("Error in dummy_group_op: %s", e.what());
  }
}


/*
 * =============================================================================
 * DATA MANIPULATION FUNCTIONS (TIDYVERSE INTEGRATION)
 * =============================================================================
 */



//' Custom DatFrame Summarization
//'
//' Parallel Dataframe column summarization example in C++.
//'
//' @param df a Dataframe
//' @param column the name a Dataframe
//'
//' @return The sum of Datframe column
//'
//' @examples
//' \dontrun{
//'
//'  library(dplyr) 
//'   my_data <- tibble(x = 1:10, group = rep(c("A", "B"), each = 5)) 
//'   my_data %>% 
//'    group_by(group) %>% 
//'    summarise(custom_sum = dmy_df_custom_summarize(cur_data(),"x"))
//' 
//' }
//'
//' @export
// [[Rcpp::export]]
Rcpp::NumericVector dmy_df_custom_summarize(Rcpp::DataFrame df, Rcpp::String column) { 
  Rcpp::NumericVector x = df[column]; 
  double total = 0;
  // The pragma tells the compiler to parallelize this loop.
  // The reduction clause handles the `total` variable safely across threads.
#ifdef _OPENMP
#pragma omp parallel for reduction(+:total)
#endif
  for (R_xlen_t i = 0; i < x.size(); ++i) {
    total += x[i];
  }
  return Rcpp::NumericVector::create(total); 
} 


//' Custom DataFrame Moving Average
//'
//' Parallel vector moving average example in C++.
//' @param x a numeric vector
//' @param width moving average window width
//'
//' @return A vector of moving averages (moviang average window reduced at edges)
//'
//' @seealso [dmy_omp_rolling_average()] for OpenMP parallel version
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
Rcpp::NumericVector dmy_df_rolling_average(Rcpp::NumericVector x, int width) {
    int len = x.size();
    Rcpp::NumericVector out(len);

    for(int i = 0; i < len; ++i) {
      double s = 0;
      int n = 0;
      for(int j = std::max(0, i - width + 1); j <= i; ++j) {
        s += x[j];
        n++;
      }
      out[i] = s / n;
    }
    return out;
}



//' Custom DataFrame Piped Transformation
//'
//' Parallel vector moving average example in C++.
//'
//' @param df an (implicit) dataframe with a "x" numeric columns
//'
//' @return A dataframe with a normalized transformed column
//'
//' @examples
//' \dontrun{
//'
//' library(dplyr)
//' library(Rcpp)
//'
//' df %>% 
//'   dmy_df_process_data() %>%
//'   filter(y > 0.1) %>%
//'   mutate(z = y * 2)
//' 
//' }
//'
//' @export
// [[Rcpp::export]]
Rcpp::DataFrame dmy_df_process_data(Rcpp::DataFrame df) {
  NumericVector x = df["x"];
  NumericVector y = exp(x) / sum(exp(x));
  return DataFrame::create(_["x"] = x, _["y"] = y);
}


//' Dummy Example of Tidyverse Funcion linkage fron C++
//'
//' Empty example for namespace environment resolution
//'
//' @return AA NULL value
//'
//' @export
// [[Rcpp::export]]
Rcpp::RObject dmy_df_call_dplyr_mutate() {
    Rcpp::Environment dplyr_ns = Rcpp::Environment::namespace_env("dplyr");
    Rcpp::Function mutate = dplyr_ns["mutate"];

    // Example usage (conceptual)
    // ... create a data frame and arguments ...
    // return mutate( ... );
    return R_NilValue; // Placeholder
}
