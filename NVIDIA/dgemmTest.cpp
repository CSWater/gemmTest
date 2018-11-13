
/* Includes, system */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cassert>
#include <fstream>


/* Includes, cuda */
#include <cublas_v2.h>
#include <cuda_runtime.h>


/* Main */
int main(int argc, char **argv) {
  cublasStatus_t status;
  double *h_A;
  double *h_B;
  double *h_C;
  double *d_A = 0;
  double *d_B = 0;
  double *d_C = 0;
  double alpha = 1.0f;
  double beta = 0.0f;
  if(argc < 4) {
	  printf("usage: ./dgemmTest m n k\n");
	  return 0;
  }
  int m, n, k;
  int lda, ldb, ldc;
  m = atoi(argv[1]);
  n = atoi(argv[2]);
  k = atoi(argv[3]);
  int i;
  double error_norm;
  double ref_norm;
  double diff;
  cublasHandle_t handle;
  cublasOperation_t transa = CUBLAS_OP_N, transb = CUBLAS_OP_T;
  if(transa == CUBLAS_OP_N) {
      lda        = m;
  }
  else {
      lda        = k;
  }
  if(transb == CUBLAS_OP_N) {
      ldb        = k;
  }
  else {
      ldb        = n;
  }
  ldc    = m;
  /* Initialize CUBLAS */
  printf("simpleCUBLAS test running..\n");

  status = cublasCreate(&handle);

  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! CUBLAS initialization error\n");
    return EXIT_FAILURE;
  }

  /* Allocate host memory for the matrices */
  h_A = reinterpret_cast<double *>(malloc(m * k * sizeof(h_A[0])));
  if (h_A == 0) {
    fprintf(stderr, "!!!! host memory allocation error (A)\n");
    return EXIT_FAILURE;
  }

  h_B = reinterpret_cast<double *>(malloc(k * n * sizeof(h_B[0])));
  if (h_B == 0) {
    fprintf(stderr, "!!!! host memory allocation error (B)\n");
    return EXIT_FAILURE;
  }

  h_C = reinterpret_cast<double *>(malloc(m * n * sizeof(h_C[0])));
  if (h_C == 0) {
    fprintf(stderr, "!!!! host memory allocation error (C)\n");
    return EXIT_FAILURE;
  }

  /* Fill the matrices with test data */
  for (i = 0; i < m * k; i++) {
    h_A[i] = rand() / static_cast<double>(RAND_MAX);
  }
  for (i = 0; i < k * n; i++) {
    h_B[i] = rand() / static_cast<double>(RAND_MAX);
  }
  for (i = 0; i < m * n; i++) {
    h_C[i] = rand() / static_cast<double>(RAND_MAX);
  }

  /* Allocate device memory for the matrices */
  if (cudaMalloc(reinterpret_cast<void **>(&d_A), m * k * sizeof(d_A[0])) !=
      cudaSuccess) {
    fprintf(stderr, "!!!! device memory allocation error (allocate A)\n");
    return EXIT_FAILURE;
  }
  if (cudaMalloc(reinterpret_cast<void **>(&d_B), n * k * sizeof(d_B[0])) !=
      cudaSuccess) {
    fprintf(stderr, "!!!! device memory allocation error (allocate B)\n");
    return EXIT_FAILURE;
  }
  if (cudaMalloc(reinterpret_cast<void **>(&d_C), m * n * sizeof(d_C[0])) !=
      cudaSuccess) {
    fprintf(stderr, "!!!! device memory allocation error (allocate C)\n");
    return EXIT_FAILURE;
  }

  /* Initialize the device matrices with the host matrices */
  status = cublasSetVector(m * k, sizeof(h_A[0]), h_A, 1, d_A, 1);
  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! device access error (write A)\n");
    return EXIT_FAILURE;
  }

  status = cublasSetVector(n * k, sizeof(h_B[0]), h_B, 1, d_B, 1);
  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! device access error (write B)\n");
    return EXIT_FAILURE;
  }

  status = cublasSetVector(m * n, sizeof(h_C[0]), h_C, 1, d_C, 1);
  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! device access error (write C)\n");
    return EXIT_FAILURE;
  }

  /* Performs operation using plain C code */

  /* Performs operation using cublas */
  status = cublasDgemm(handle, transa, transb, m, n, k, &alpha, d_A, lda, d_B, ldb, &beta, d_C, ldc);

  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! kernel execution error.\n");
    return EXIT_FAILURE;
  }

  /* Read the result back */
  status = cublasGetVector(m * n, sizeof(h_C[0]), d_C, 1, h_C, 1);

  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! device access error (read C)\n");
    return EXIT_FAILURE;
  }

  /* Memory clean up */
  free(h_A);
  free(h_B);
  free(h_C);

  if (cudaFree(d_A) != cudaSuccess) {
    fprintf(stderr, "!!!! memory free error (A)\n");
    return EXIT_FAILURE;
  }
  if (cudaFree(d_B) != cudaSuccess) {
    fprintf(stderr, "!!!! memory free error (B)\n");
    return EXIT_FAILURE;
  }
  if (cudaFree(d_C) != cudaSuccess) {
    fprintf(stderr, "!!!! memory free error (C)\n");
    return EXIT_FAILURE;
  }
  /* Shutdown */
  status = cublasDestroy(handle);

  if (status != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "!!!! shutdown error (A)\n");
    return EXIT_FAILURE;
  }

}
