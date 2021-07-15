#pragma once
#include <gsl/gsl_math.h>
#include <gsl/gsl_eigen.h>
#include <gsl/gsl_sf_gamma.h>
#include <gsl/gsl_poly.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_linalg.h>

#include "moments.h"
#include "grids.h"
#include <cublas_v2.h>

class LaguerreTransform {
 public:

  LaguerreTransform(Grids* grids, int batch_size);
  ~LaguerreTransform();
  
  void transformToGrid(float* G_in, float* g_res);
  void transformToSpectral(float* g_in, float* G_res);

  float * get_toGrid() {return toGrid;}
  float * get_toSpectral() {return toSpectral;}
  float * get_roots() {return roots;}
  const int L;
  const int J;

 private:
  Grids * grids_     ; 
  float * toGrid     ;
  float * toSpectral ;
  float * roots      ;

  void initTransforms(float* toGrid, float* toSpectral, float* roots);

  cublasHandle_t handle;

  // batch_size = number of hermite moments to transform 
  const int batch_size_;
};


