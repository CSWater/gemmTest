/* ************************************************************************
 * Copyright 2016 Advanced Micro Devices, Inc.
 * ************************************************************************ */

#include <stdlib.h>
#include <dlfcn.h>
#include <stdio.h>
#include <sys/time.h>
#include <vector>
#include <limits>
#include <iostream>
#include <fstream>
#include <rocblas.h>
#include <hip/hip_runtime.h>
#include "help.h"
const int REPEATED = 10;
const int CASES = 10;
using namespace std;

const rocblas_int DIM1 = 1023;
const rocblas_int DIM2 = 1024;
const rocblas_int DIM3 = 1025;

int main(int argc, char *argv[]) {
  rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_transpose;
  float alpha = 1.1, beta = 0.9;
  rocblas_int m = DIM1, n = DIM2, k = DIM3;
  if(argc < 4) {
    cout << "Usage ./dgemmTest m n k. Now use default m n k" << std::endl;
  }
  else {
    m = atoi(argv[1]);
    n = atoi(argv[2]);
    k = atoi(argv[3]);
  }
  rocblas_int lda, ldb, ldc, size_a, size_b, size_c;
  int a_stride_1, a_stride_2, b_stride_1, b_stride_2;
  //cout << "dgemm performance test" << endl;
  if(transa == rocblas_operation_none) {
      lda        = m;
      size_a     = k * lda;
      a_stride_1 = 1;
      a_stride_2 = lda;
      cout << "N";
  }
  else {
      lda        = k;
      size_a     = m * lda;
      a_stride_1 = lda;
      a_stride_2 = 1;
      cout << "T";
  }
  if(transb == rocblas_operation_none) {
      ldb        = k;
      size_b     = n * ldb;
      b_stride_1 = 1;
      b_stride_2 = ldb;
      cout << "N: ";
  }
  else {
      ldb        = n;
      size_b     = k * ldb;
      b_stride_1 = ldb;
      b_stride_2 = 1;
      cout << "T: ";
  }
  ldc    = m;
  size_c = n * ldc;

  // Naming: da is in GPU (device) memory. ha is in CPU (host) memory
  vector<float> ha(size_a);
  vector<float> hb(size_b);
  vector<float> hc(size_c);
  vector<float> hc_gold(size_c);

  // initial data on host
  srand(1);
  for(int i = 0; i < size_a; ++i) {
      ha[i] = rand() % 17;
  }
  for(int i = 0; i < size_b; ++i) {
      hb[i] = rand() % 17;
  }
  for(int i = 0; i < size_c; ++i) {
      hc[i] = rand() % 17;
  }
  hc_gold = hc;

  // allocate memory on device
  float *da, *db, *dc;
  CHECK_HIP_ERROR(hipMalloc(&da, size_a * sizeof(float)));
  CHECK_HIP_ERROR(hipMalloc(&db, size_b * sizeof(float)));
  CHECK_HIP_ERROR(hipMalloc(&dc, size_c * sizeof(float)));

  // copy matrices from host to device
  CHECK_HIP_ERROR(hipMemcpy(da, ha.data(), sizeof(float) * size_a, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(db, hb.data(), sizeof(float) * size_b, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(dc, hc.data(), sizeof(float) * size_c, hipMemcpyHostToDevice));

  rocblas_handle handle;
  CHECK_ROCBLAS_ERROR(rocblas_create_handle(&handle));

  float elapased_time = 0.0;
	double tflops = 0.0;
  hipEvent_t event_start, event_stop;
  CHECK_ROCBLAS_ERROR(
    rocblas_sgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc) );

  GPU_TIMER_START(elapased_time, event_start, event_stop);
  rocblas_sgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
  GPU_TIMER_END(elapased_time, event_start, event_stop);
	tflops = 1e-12 * 2 * m * n * k / elapased_time;
  cout << "m, n, k, time, tflops= " << m << ", " << n << ", " << k << ", " << elapased_time << ", " << tflops << endl;

/*
  // copy output from device to CPU
  CHECK_HIP_ERROR(hipMemcpy(hc.data(), dc, sizeof(double) * size_c, hipMemcpyDeviceToHost));



  double max_relative_error = numeric_limits<double>::min();

  // calculate golden or correct result
  mat_mat_mult<double>(alpha,
                      beta,
                      m,
                      n,
                      k,
                      ha.data(),
                      a_stride_1,
                      a_stride_2,
                      hb.data(),
                      b_stride_1,
                      b_stride_2,
                      hc_gold.data(),
                      1,
                      ldc);

  for(int i = 0; i < size_c; i++)
  {
      double relative_error = (hc_gold[i] - hc[i]) / hc_gold[i];
      relative_error       = relative_error > 0 ? relative_error : -relative_error;
      max_relative_error =
          relative_error < max_relative_error ? max_relative_error : relative_error;
  }
  double eps       = numeric_limits<double>::epsilon();
  double tolerance = 10;
  if(max_relative_error != max_relative_error || max_relative_error > eps * tolerance)
  {
      cout << "FAIL: max_relative_error = " << max_relative_error << endl;
  }
  else
  {
      cout << "PASS: max_relative_error = " << max_relative_error << endl;
  }
  */

  CHECK_HIP_ERROR(hipFree(da));
  CHECK_HIP_ERROR(hipFree(db));
  CHECK_HIP_ERROR(hipFree(dc));
  CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
  return EXIT_SUCCESS;
}
