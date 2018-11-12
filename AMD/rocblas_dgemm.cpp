/* ************************************************************************
 * Copyright 2016 Advanced Micro Devices, Inc.
 * ************************************************************************ */

#include <stdlib.h>
#include <dlfcn.h>
#include <stdio.h>
#include <sys/time.h>
#include <vector>
#include <limits>
#include "rocblas.h"
#include <iostream>
#include <fstream>
const int REPEATED = 10;
const int CASES = 10;
using namespace std;
/*  timing:*/
/*! \brief  CPU Timer(in microsecond): synchronize with the default device and return wall time */
double get_time_us(void) {
    hipDeviceSynchronize();
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000 * 1000) + tv.tv_usec;
};

/*! \brief  CPU Timer(in microsecond): synchronize with given queue/stream and return wall time */
double get_time_us_sync(hipStream_t stream) {
    hipStreamSynchronize(stream);
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000 * 1000) + tv.tv_usec;
};

#ifndef CHECK_HIP_ERROR
#define CHECK_HIP_ERROR(error)                    \
    if(error != hipSuccess)                       \
    {                                             \
        fprintf(stderr,                           \
                "Hip error: '%s'(%d) at %s:%d\n", \
                hipGetErrorString(error),         \
                error,                            \
                __FILE__,                         \
                __LINE__);                        \
        exit(EXIT_FAILURE);                       \
    }
#endif

#ifndef CHECK_ROCBLAS_ERROR
#define CHECK_ROCBLAS_ERROR(error)                              \
    if(error != rocblas_status_success)                         \
    {                                                           \
        fprintf(stderr, "rocBLAS error: ");                     \
        if(error == rocblas_status_invalid_handle)              \
            fprintf(stderr, "rocblas_status_invalid_handle");   \
        if(error == rocblas_status_not_implemented)             \
            fprintf(stderr, " rocblas_status_not_implemented"); \
        if(error == rocblas_status_invalid_pointer)             \
            fprintf(stderr, "rocblas_status_invalid_pointer");  \
        if(error == rocblas_status_invalid_size)                \
            fprintf(stderr, "rocblas_status_invalid_size");     \
        if(error == rocblas_status_memory_error)                \
            fprintf(stderr, "rocblas_status_memory_error");     \
        if(error == rocblas_status_internal_error)              \
            fprintf(stderr, "rocblas_status_internal_error");   \
        fprintf(stderr, "\n");                                  \
        exit(EXIT_FAILURE);                                     \
    }
#endif

const rocblas_int DIM1 = 1023;
const rocblas_int DIM2 = 1024;
const rocblas_int DIM3 = 1025;

typedef rocblas_status (*dgemm_type)(rocblas_handle handle,
                                            rocblas_operation transa,
                                            rocblas_operation transb,
                                            rocblas_int m,
                                            rocblas_int n,
                                            rocblas_int k,
                                            const double* alpha,
                                            const double* A,
                                            rocblas_int lda,
                                            const double* B,
                                            rocblas_int ldb,
                                            const double* beta,
                                            double* C,
                                            rocblas_int ldc);
template <typename T>
void mat_mat_mult(T alpha,
                  T beta,
                  int M,
                  int N,
                  int K,
                  T* A,
                  int As1,
                  int As2,
                  T* B,
                  int Bs1,
                  int Bs2,
                  T* C,
                  int Cs1,
                  int Cs2) {
  for(int i1 = 0; i1 < M; i1++) {
    for(int i2 = 0; i2 < N; i2++) {
      T t = 0.0;
      for(int i3 = 0; i3 < K; i3++) {
          t += A[i1 * As1 + i3 * As2] * B[i3 * Bs1 + i2 * Bs2];
      }
      C[i1 * Cs1 + i2 * Cs2] = beta * C[i1 * Cs1 + i2 * Cs2] + alpha * t;
    }
  }
}

int main() {
  //rocblas_operation transa = rocblas_operation_none, transb = rocblas_operation_transpose;
  rocblas_operation transa = rocblas_operation_transpose, transb = rocblas_operation_none;
  double alpha = 1.1, beta = 0.9;
  void *dgemm_trained = NULL; 
  dgemm_trained = dlopen("/home/shchy/code/rocBLAS/build/release/rocblas-install/lib/librocblas.so", RTLD_LAZY);
  if(!dgemm_trained) {
    std::cout << "no rocblas found in the destination dir" << std::endl;
  }
  dgemm_type dgemm_ptr = (dgemm_type)dlsym(dgemm_trained, "rocblas_dgemm");
  rocblas_int m = DIM1, n = DIM2, k = DIM3;
  ifstream fin("tt.txt");
  rocblas_int gemm[CASES][3];
  for(int i = 0; i < CASES; i++) {
    fin >> gemm[i][0] >> gemm[i][1] >> gemm[i][2];
  }
  rocblas_int lda, ldb, ldc, size_a, size_b, size_c;
  int a_stride_1, a_stride_2, b_stride_1, b_stride_2;
  cout << "dgemm performance test" << endl;
  for(int index = 0; index < CASES; index++) {
    m = gemm[index][0];
    n = gemm[index][1];
    k = gemm[index][2];
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
    vector<double> ha(size_a);
    vector<double> hb(size_b);
    vector<double> hc(size_c);
    vector<double> hc_gold(size_c);

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

    CHECK_ROCBLAS_ERROR(
      //rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc));
      dgemm_ptr(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc));

    double gpu_time_used;
	  double tflops = 0.0;
	  gpu_time_used = get_time_us();			//in microseconds
	  for(int i = 0; i < REPEATED; i++) {
      //rocblas_dgemm(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
      dgemm_ptr(handle, transa, transb, m, n, k, &alpha, da, lda, db, ldb, &beta, dc, ldc);
    }
	  gpu_time_used = (get_time_us() - gpu_time_used) / 1e6;
	  tflops = 1e-12 * 2 * m * n * k * REPEATED / gpu_time_used;
    cout << "m, n, k, time, tflops= " << m << ", " << n << ", " << k << ", " << gpu_time_used / REPEATED << ", " << tflops << endl;
    CHECK_HIP_ERROR(hipFree(da));
    CHECK_HIP_ERROR(hipFree(db));
    CHECK_HIP_ERROR(hipFree(dc));
    CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
  } 

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

  CHECK_HIP_ERROR(hipFree(da));
  CHECK_HIP_ERROR(hipFree(db));
  CHECK_HIP_ERROR(hipFree(dc));
  CHECK_ROCBLAS_ERROR(rocblas_destroy_handle(handle));
  */
  return EXIT_SUCCESS;
}
