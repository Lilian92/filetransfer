EXE=cuda_prog_1
SRC=cuda_prog_1.cu
CFLAGES=-O3 -std=c++11

ifdef USE_FAST_MATH
    CFLAGES += -use_fast_math
endif

$(EXE): $(SRC)
	nvcc -o $@ $^ $(CFLAGES)

clean:
	rm -vf $(EXE)
