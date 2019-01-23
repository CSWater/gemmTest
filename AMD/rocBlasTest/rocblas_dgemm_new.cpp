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
#include "rocblas.h"
#include <hip/hip_runtime.h>
#include "help.h"
const int REPEATED = 10;
const int CASES = 10;
using namespace std;

int main(int argc, char *argv[]) {
  hipSetDevice(2);
  rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_none;
  //rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_none;
  double alpha = -1, beta = 1;
  rocblas_int lda, ldb, ldc, size_a, size_b, size_c;
  rocblas_int m, n, k;

  if(argc != 4) {
    printf("wrong parameters\n");
    return -1;
  }
  else {
    m = atoi(argv[1]);
    n = atoi(argv[2]);
    k = atoi(argv[3]);
  }
  //cout << "dgemm performance test" << endl;
  if(transa == rocblas_operation_none) {
      lda        = m;
      size_a     = k * lda;
      //cout << "N";
  }
  else {
      lda        = k;
      size_a     = m * lda;
      //cout << "T";
  }
  if(transb == rocblas_operation_none) {
      ldb        = k;
      size_b     = n * ldb;
      //cout << "N: ";
  }
  else {
      ldb        = n;
      size_b     = k * ldb;
      //cout << "T: ";
  }
  ldc    = m;
  size_c = n * ldc;

  // Naming: da is in GPU (device) memory. ha is in CPU (host) memory
  vector<double> ha(size_a);
  vector<double> hb(size_b);
  vector<double> hc(size_c);
  vector<double> hc_gold(size_c);

  // initial data on host
  srand(1);
  for(int i = 0; i < size_a; ++i) {
      ha[i] = rand() * 1.0 / RAND_MAX;
  }
  for(int i = 0; i < size_b; ++i) {
      hb[i] = rand() * 1.0 / RAND_MAX;
  }
  for(int i = 0; i < size_c; ++i) {
      hc[i] = rand() * 1.0 / RAND_MAX;
  }
  hc_gold = hc;

  // allocate memory on device
  double *da, *db, *dc;
  CHECK_HIP_ERROR(hipMalloc(&da, size_a * sizeof(double)));
  CHECK_HIP_ERROR(hipMalloc(&db, size_b * sizeof(double)));
  CHECK_HIP_ERROR(hipMalloc(&dc, size_c * sizeof(double)));

  // copy matrices from host to device
  CHECK_HIP_ERROR(hipMemcpy(da, ha.data(), sizeof(double) * size_a, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(db, hb.data(), sizeof(double) * size_b, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(dc, hc.data(), sizeof(double) * size_c, hipMemcpyHostToDevice));

  rocblas_handle handle;
  CHECK_ROCBLAS_ERROR(rocblas_create_handle(&handle));

  float elapased_time = 0.0;
	double tflops = 0.0;
  hipEvent_t event_start, event_stop;
  CHECK_ROCBLAS_ERROR(
    rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc) 
  );
  GPU_TIMER_START(elapased_time, event_start, event_stop);
  rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
  GPU_TIMER_END(elapased_time, event_start, event_stop);
	tflops = 1e-12 * 2 * m * n * k / elapased_time;
  cout << "m, n, k, lda, ldb, time, tflops, eff=, " << m << ", " << n << ", " << k << ", "  
      << lda << ", " << ldb << " " << elapased_time << ", " << tflops << ", " << tflops / 6.5 * 100 << "%" << endl;

  CHECK_HIP_ERROR(hipFree(da));
  CHECK_HIP_ERROR(hipFree(db));
  CHECK_HIP_ERROR(hipFree(dc));
  CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
  return EXIT_SUCCESS;
}
