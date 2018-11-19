#include "rocblas.h"

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

