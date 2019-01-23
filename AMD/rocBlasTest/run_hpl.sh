#!/bin/bash
while read m n k lda ldb ldc
do
  ./rocblas_dgemm_new ${m} ${n} ${k} ${lda} ${ldb} ${ldc}
done < mnk_uniq
