#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <sys/time.h>
#include <string.h>
#include "cblas.h"


#define OUT_CSV
//#define ACCURACY_CHECK

struct timeval UTIL_CPU_TIME_start, UTIL_CPU_TIME_end;

void UTIL_CPU_TIME_tic(){
    gettimeofday(&UTIL_CPU_TIME_start, NULL);
}

double UTIL_CPU_TIME_toc(){
    gettimeofday(&UTIL_CPU_TIME_end, NULL);
    double result = (UTIL_CPU_TIME_end.tv_sec - UTIL_CPU_TIME_start.tv_sec) + \
	  	    (UTIL_CPU_TIME_end.tv_usec - UTIL_CPU_TIME_start.tv_usec) / 1000000.0;
    return result;
}

CBLAS_TRANSPOSE getTranspose(char trans){
    if(trans == 'N' || trans == 'n')
        return CblasNoTrans;
    else
        return CblasTrans;
}
int main(int argc, char* argv[])
{
    // column major
    int iter_num = atoi(argv[1]);
    // Linear dimension of matrices
    char trans_a = argv[2][0];
    char trans_b = argv[2][1];
    size_t m = atoi(argv[3]);
    size_t n = atoi(argv[4]);
    size_t k = atoi(argv[5]);
    assert(trans_a == 'N' || trans_a == 'T');
    assert(trans_b == 'N' || trans_b == 'T');
    size_t lda, ldb, ldc;
    size_t rows_a, rows_b, rows_c;
    size_t cols_a, cols_b, cols_c;
    if(trans_a == 'N'){
        lda = m;
        rows_a = m;
        cols_a = k;
    }
    else{
        lda = k;
        rows_a = k;
        cols_a = m;
    }
    if(trans_b == 'N'){
        ldb = k;
        rows_b = k;
        cols_b = n;
    }
    else{
        ldb = n;
        rows_b = n;
        cols_b = k;
    }
    ldc = m;
    rows_c = m;
    cols_c = n;

    // DGEMM: C = alpha*Amk*Bkn + beta*Cmn
    double alpha = -1.0;
    double beta  = 1.1;
    double EPSILON = 0.0001;

    // Allocate host storage for A,B,C square matrices
    double *A, *B, *C, *CC;
    A  = (double*)malloc(lda * cols_a * sizeof(double));
    B  = (double*)malloc(ldb * cols_b * sizeof(double));
    C  = (double*)malloc(ldc * cols_c * sizeof(double));
    //CC = (double*)malloc(ldc * cols_c * sizeof(double));

    // Matrices are arranged column major
    size_t i, j, index;
    for(j=0; j<cols_a; j++) {
        for(i=0; i<rows_a; i++) {
            index = j * lda + i;
            A[index] = sin(index);
        } 
    }
    for(j=0; j<cols_b; j++) {
        for(i=0; i<rows_b; i++) {
            index = j * ldb + i;
            B[index] = sin(index);
        }
    }
    for(j=0; j<cols_c; j++) {
        for(i=0; i<rows_c; i++) {
            index = j * ldc + i;
            C[index] = cos(index);
	   //       CC[index] = cos(index);
        }
    }

    double time_stage = 0.0;
    //warm up
    cblas_dgemm(CblasColMajor,
                getTranspose(trans_a), getTranspose(trans_b),
                m, n, k,
                alpha,
                A, lda,
                B, ldb,
                beta,
                C, ldc);
    for(index = 0; index<iter_num; index++){
      //  memcpy(CC, C, sizeof(double) * ldc * cols_c);
        UTIL_CPU_TIME_tic();
        cblas_dgemm(CblasColMajor,
                    getTranspose(trans_a), getTranspose(trans_b),
                    m, n, k,
                    alpha,
                    A, lda,
                    B, ldb,
                    beta,
                    C, ldc);
	      time_stage += UTIL_CPU_TIME_toc();
    }

    double gemm_perf = 2.0 * 1e-9 * m * n * k / (time_stage / iter_num);
    double gemm_time = 1.0 * time_stage / iter_num;
#ifdef OUT_CSV
    printf("%c,%c,%d,%d,%d,%.4lf,%lf\n",
           trans_a, trans_b,
           m, n, k,
           gemm_perf,gemm_time);
#else
    printf("DGEMM Performance: transa %c transb %c m %d - n %d - k %d - gemm %.5lfs %.3lf TFLOPS\n",
           trans_a, trans_b,
           m, n, k,
           time_stage/iter_num,
           gemm_perf);
#endif
//#ifdef ACCURACY_CHECK
//    // Accuracy check
//    size_t A_index, B_index, C_index;
//    for(i=0; i<m; i++){
//        for(j=0; j<n; j++){
//            double element = 0;
//            for(index=0; index<k; index++){
//                 if(trans_a == 'N')
//                     A_index = index * lda + i;
//                 else
//                     A_index = i * lda + index;
//                 if(trans_b == 'N')
//                     B_index = j * ldb + index;
//                 else
//                     B_index = index * ldb + j;
//                 
//                 element += alpha * A[A_index] * B[B_index];
//            }
//            C_index = j * ldc + i;
//            element += beta * C[C_index];
//            assert(abs(element - CC[C_index]) < EPSILON);
//        }
//    }
//#endif
    // Clean up resources
    free(A);
    free(B);
    free(C);
    free(CC);

    return 0;
}
