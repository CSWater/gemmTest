CC=gcc
BLIS_PATH=
LD_BLIS= $(BLIS_PATH)/lblis -fopenmp -lm
CFLAGS= -O3
all: gemm_blis 

gemm_blis: cpu_gemm.c
	$(CC) $(CFLAGS) -I./include cpu_gemm.c -o gemm_blis $(LD_BLIS)

clean:
	rm gemm_blis -rf
