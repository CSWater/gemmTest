ROCBLAS_INSTALL_DIR=/opt/rocm/rocblas
ROCBLAS_INCLUDE=$(ROCBLAS_INSTALL_DIR)/include
ROCBLAS_LIB_PATH=$(ROCBLAS_INSTALL_DIR)/lib
ROCBLAS_LIB=rocblas
#HIP_INCLUDE=/opt/rocm/hip/include
LDFLAGS=-L$(ROCBLAS_LIB_PATH) -l$(ROCBLAS_LIB) -ldl
LD=hipcc
CFLAGS=-I$(ROCBLAS_INCLUDE) #-I$(HIP_INCLUDE) #-g
CPP=hipcc
EXE=rocblas_dgemm rocblas_sgemm 

all: $(EXE)

%.o : %.cpp
	$(CPP) -c -o $@ $< $(CFLAGS)

rocblas_dgemm : rocblas_dgemm.o
	$(LD) $< $(LDFLAGS) -o $@
rocblas_sgemm : rocblas_sgemm.o
	$(LD) $< $(LDFLAGS) -o $@

clean:
	rm -f $(EXE) 
	rm -f *.o
