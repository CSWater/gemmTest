CC=gcc
BLIS_PATH=/home/sugon/Hygon/hygonblis-deliver-0831
LD_BLIS= -L$(BLIS_PATH)/lib -lblis -fopenmp -lm
CFLAGS= -O3
all: gemm_blis 

gemm_blis: cpu_gemm.c
	$(CC) $(CFLAGS) -I./include cpu_gemm.c -o gemm_blis $(LD_BLIS)

clean:
	rm gemm_blis -rf
