# --------------------------------------------------------
# Compiler settings
# --------------------------------------------------------
CC      := clang
ISPC    := ispc
FUTHARK := futhark

CFLAGS  := -Ofast -march=native -mtune=native -ffast-math -fstrict-aliasing \
           -funroll-loops -fomit-frame-pointer -fvectorize -fslp-vectorize \
           -Rpass=loop-vectorize -Rpass=slp-vectorize -DNDEBUG

LDFLAGS := -lm -lpng -lturbojpeg

BUILD   := build
SRC     := src

# --------------------------------------------------------
# Targets
# --------------------------------------------------------
all: $(BUILD)/a.out

# 1. Run futhark to generate wu.c and wu.kernels.ispc
$(BUILD)/wu.c $(BUILD)/wu.kernels.ispc: $(SRC)/wu.fut
	$(FUTHARK) ispc --library $< -o $(BUILD)/wu

# 2. Compile ISPC kernels
$(BUILD)/wu.kernels.o: $(BUILD)/wu.kernels.ispc
	$(ISPC) -o $@ $< --addressing=32 --pic --woff -O3

# 3. Final binary: clang + your C files + ISPC object
$(BUILD)/a.out: $(BUILD)/wu.c $(SRC)/quantize.c $(BUILD)/wu.kernels.o
	$(CC) $(CFLAGS) $(BUILD)/wu.c $(SRC)/quantize.c $(BUILD)/wu.kernels.o \
		$(LDFLAGS) -o $@

# Misc
clean:
	rm -rf $(BUILD)/*.o $(BUILD)/*.c $(BUILD)/*.ispc $(BUILD)/a.out $(BUILD)/*.h $(BUILD)/*.json

.PHONY: all clean

