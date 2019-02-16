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

const rocblas_int DIM1 = 1023;
const rocblas_int DIM2 = 1024;
const rocblas_int DIM3 = 1025;

int main(int argc, char *argv[]) {
  //hipSetDevice(2);
  double alpha = 1.1, beta = 0.9;
  //void *dgemm_trained = NULL; 
  //dgemm_trained = dlopen("/home/scy/code/rocBLAS/build/release/rocblas-install/lib/librocblas.so", RTLD_LAZY);
  //if(!dgemm_trained) {
  //  std::cout << "no rocblas found in the destination dir" << std::endl;
  //  return -1;
  //}
  //dgemm_type dgemm_ptr = (dgemm_type)dlsym(dgemm_trained, "rocblas_dgemm");
  rocblas_int m = DIM1, n = DIM2, k = DIM3;
  rocblas_int lda, ldb, ldc;
  rocblas_int size_a, size_b, size_c;
  rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_transpose;
  string trans;
  if(argc != 8) {
    cout << "Usage ./dgemmTest transAtransB m n k lda ldb ldc. Now use default params" << std::endl;
    lda = m;
    ldb = n;
    ldc = m;
    cout << "NT: ";
  }
  else {
    trans = string(argv[1]);
    m = atoi(argv[2]);
    n = atoi(argv[3]);
    k = atoi(argv[4]);
    lda = atoi(argv[5]);
    ldb = atoi(argv[6]);
    ldc = atoi(argv[7]);
  }

  if(trans.compare("NN") == 0) {
    transa = rocblas_operation_none;
    transb = rocblas_operation_none;
  } 
  else if(trans.compare("NT") == 0) {
    transa = rocblas_operation_none;
    transb = rocblas_operation_transpose;
  }
  else if(trans.compare("TN") == 0) {
    transa = rocblas_operation_transpose;
    transb = rocblas_operation_none;
  }
  else if(trans.compare("TT") == 0) {
    transa = rocblas_operation_transpose;
    transb = rocblas_operation_transpose;
  }
  else {
    cout << "Invalid Format!\n";
    return -1;
  }

  if(transa == rocblas_operation_none) {
      size_a     = k * lda;
      cout << "N";
  }
  else {
      size_a     = m * lda;
      cout << "T";
  }
  if(transb == rocblas_operation_none) {
      size_b     = n * ldb;
      cout << "N: ";
  }
  else {
      size_b     = k * ldb;
      cout << "T: ";
  }
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
  CHECK_ROCBLAS_ERROR(rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc) );
  //CHECK_ROCBLAS_ERROR(rdgemm_ptr(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc) );

  GPU_TIMER_START(elapased_time, event_start, event_stop);
  rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
  //dgemm_ptr(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
  GPU_TIMER_END(elapased_time, event_start, event_stop);
	tflops = 1e-12 * 2 * m * n * k / elapased_time;
  //cout << "m, n, k, time, tflops, eff=, " << m << ", " << n << ", " << k << ", " << elapased_time << ", " << tflops << ", " << tflops / 6.5 * 100 << "%"<< endl;
  printf("m, n, k, lda, ldb, ldc, tflops, eff=, %5d, %5d, %5d, %5d, %5d, %5d, %.2f, %.2f%%\n",
      m, n, k, lda, ldb, ldc, tflops, tflops / 6.5 * 100 );

  CHECK_HIP_ERROR(hipMemcpy(hc.data(), dc, sizeof(double) * size_c, hipMemcpyDeviceToHost));

  CHECK_HIP_ERROR(hipFree(da));
  CHECK_HIP_ERROR(hipFree(db));
  CHECK_HIP_ERROR(hipFree(dc));
  CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
  return EXIT_SUCCESS;
}
