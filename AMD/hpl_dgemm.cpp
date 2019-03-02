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
  double alpha = 1.1, beta = 0.9;
  rocblas_int m, n, k;
  rocblas_int lda, ldb, ldc;
  rocblas_int size_a, size_b, size_c;
  int DIM1, DIM2, DIM3, LDA, LDB, LDC;
  
  rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_transpose;
  string test_file;
  if(argc != 8) {
    cout << "Error params for run hpl" << std::endl;
  }
  else {
    cout << "run hpl simulation" << std::endl;
    test_file = string(argv[1]);
    DIM1 = atoi(argv[2]);
    DIM2 = atoi(argv[3]);
    DIM3 = atoi(argv[4]);
    LDA = atoi(argv[5]);
    LDB = atoi(argv[6]);
    LDC = atoi(argv[7]);
  }
  size_a = LDA * DIM3;
  size_b = LDB * DIM3;
  size_c = LDB * LDA;

  // Naming: da is in GPU (device) memory. ha is in CPU (host) memory
  vector<double> ha(size_a);
  vector<double> hb(size_b);
  vector<double> hc(size_c);
  vector<double> hcc(size_c);
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

  // allocate memory on device
  double *da, *db, *dc;
  CHECK_HIP_ERROR(hipMalloc(&da, size_a * sizeof(double)));
  CHECK_HIP_ERROR(hipMalloc(&db, size_b * sizeof(double)));
  CHECK_HIP_ERROR(hipMalloc(&dc, size_c * sizeof(double)));

  // copy matrices from host to device
  CHECK_HIP_ERROR(hipMemcpy(da, ha.data(), sizeof(double) * size_a, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(db, hb.data(), sizeof(double) * size_b, hipMemcpyHostToDevice));
  CHECK_HIP_ERROR(hipMemcpy(dc, hc.data(), sizeof(double) * size_c, hipMemcpyHostToDevice));

  string trans;
  std::ifstream fin(test_file.c_str());
  int i = 0;
  while (fin >> trans >> m >> n >> k >> lda >> ldb >> ldc) {
    //printf("%d, %d, %d, %d, %d, %d\n", m, n, k, lda, ldb, ldc);
    if(trans.compare("NN") == 0) {
      transa = rocblas_operation_none;
      transb = rocblas_operation_none;
      continue;
    } 
    else if(trans.compare("NT") == 0) {
      transa = rocblas_operation_none;
      transb = rocblas_operation_transpose;
    }
    else if(trans.compare("TN") == 0) {
      transa = rocblas_operation_transpose;
      transb = rocblas_operation_none;
      continue;
    }
    else if(trans.compare("TT") == 0) {
      transa = rocblas_operation_transpose;
      transb = rocblas_operation_transpose;
      continue;
    }
    else {
      cout << "Invalid Format!\n";
      return -1;
    }

    if(transa == rocblas_operation_none) {
        cout << "N";
    }
    else {
        cout << "T";
    }
    if(transb == rocblas_operation_none) {
        cout << "N: ";
    }
    else {
        cout << "T: ";
    }
    
    rocblas_handle handle;
    CHECK_ROCBLAS_ERROR(rocblas_create_handle(&handle));

    float elapased_time = 0.0;
	  double tflops = 0.0;
    hipEvent_t event_start, event_stop;
    CHECK_ROCBLAS_ERROR(rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc) );

    GPU_TIMER_START(elapased_time, event_start, event_stop);
    rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
    GPU_TIMER_END(elapased_time, event_start, event_stop);
	  tflops = 1e-12 * 2 * m * n * k / elapased_time;
    printf("m, n, k, lda, ldb, ldc, tflops, eff=, %5d, %5d, %5d, %5d, %5d, %5d, %.2f, %.2f%%\n",
      m, n, k, lda, ldb, ldc, tflops, tflops / 6.5 * 100 );
    CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
    //if(i % 500 == 0) {
    //  CHECK_HIP_ERROR(hipMemcpy(hcc.data(), dc, sizeof(double) * size_c, hipMemcpyDeviceToHost));
    //  CHECK_HIP_ERROR(hipMemcpy(dc, hc.data(), sizeof(double) * size_c, hipMemcpyHostToDevice));
    //}
  }



  CHECK_HIP_ERROR(hipFree(da));
  CHECK_HIP_ERROR(hipFree(db));
  CHECK_HIP_ERROR(hipFree(dc));
  return EXIT_SUCCESS;
}
