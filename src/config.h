#pragma once

// config.h: static project configuration

// this file cold be generted by a standard `configuration` script
// a configuration script example is provided in
// ..//notes/howtos/Rcpp-HOWTO.md#A2-perplexity


// RcppEigen
//
// enable BLAS/LAPACK support
//
// @see: https://libeigen.gitlab.io/eigen/docs-nightly/TopicUsingBlasLapack.html

//#define EIGEN_USE_BLAS 1
//#define EIGEN_USE_LAPACKE 1
#define EIGEN_PERMANENTLY_DISABLE_STUPID_WARNINGS 1


#undef HAVE_EIGEN
/* 
#define HAVE_EIGEN 1  // #{GSL}
*/




// to enable GSL support:
//
// - install gsl: i.e. "apt install libgsl-dev"
//
// - in DESCRIPTION:
//     - add RcppGSL to Depends and LinkingTo
//     - add 'GSL (>= 2.0)' to SystemRequirements
//
// - in src/Makevars
//      - add the following:
//
//    ```makefile
//
//    # Get GSL flags from gsl-config
//    GSL_CFLAGS = $(shell gsl-config --cflags)
//    GSL_LIBS = $(shell gsl-config --libs)
//
//    # Package-specific flags
//    PKG_CPPFLAGS = -I../inst/include
//    PKG_CXXFLAGS = -fopenmp $(GSL_CFLAGS)
//    PKG_LIBS = -fopenmp $(GSL_LIBS)
//
//    ```
//
// -  define macro HAVE_GSL
//

#undef HAVE_GSL
/* 
#define HAVE_GSL 1  // #{GSL}
*/




  
