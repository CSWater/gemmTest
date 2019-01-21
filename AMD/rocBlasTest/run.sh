#!/bin/bash
for N in {44160..384..-384}
do
  ./rocblas_dgemm ${M} 2048 384
done
