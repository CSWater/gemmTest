iter_num=3      #repeated test times
format=NN
NUM_THREADS=$1  #thread num
echo "Threads: " ${NUM_THREADS} "iter_num: " ${iter_num}

EXE_BLIS=./gemm_blis
  echo "blis"
  export BLIS_NUM_THREADS=${NUM_THREADS}
  export OMP_PLACES=cores
  export OMP_PROC_BIND=close
  ${EXE_BLIS} ${iter_num} ${format} 44160 192 192
  #for size in {10000..12000..64}
  #do
  #  ${EXE_BLIS} ${iter_num} ${format} ${size} ${size} ${size}
  #done
