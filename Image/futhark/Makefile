# --------------------------------------------------------
# Compiler settings
# --------------------------------------------------------
CC      := clang
ISPC    := ispc
FUTHARK := futhark

CFLAGS  := -O3 -march=native -mtune=native -ffast-math -fstrict-aliasing \
           -funroll-loops -fomit-frame-pointer -DNDEBUG

LDFLAGS := -lm -lpng -lturbojpeg

BUILD   := build
SRC     := src

# --------------------------------------------------------
# Targets
# --------------------------------------------------------
all: $(BUILD)/a.out

# 1. Run futhark to generate wu.c and wu.kernels.ispc
$(BUILD)/celebi.c $(BUILD)/celebi.kernels.ispc: $(SRC)/celebi.fut $(SRC)/wu.fut $(SRC)/wsmeans.fut
	$(FUTHARK) ispc --library $(SRC)/celebi.fut -o $(BUILD)/celebi

# 2. Compile ISPC kernels
$(BUILD)/celebi.kernels.o: $(BUILD)/celebi.kernels.ispc
	$(ISPC) -o $@ $< --addressing=32 --pic --woff -O3

# 3. Final binary: clang + your C files + ISPC object
$(BUILD)/a.out: $(BUILD)/celebi.c $(SRC)/quantize.c $(BUILD)/celebi.kernels.o $(SRC)/load_image.h $(SRC)/sample_image.h
	$(CC) $(CFLAGS) $(BUILD)/celebi.c $(SRC)/quantize.c $(BUILD)/celebi.kernels.o \
		$(LDFLAGS) -o $@


# Misc
clean:
	rm -rf $(BUILD)/*.o $(BUILD)/*.c $(BUILD)/*.ispc $(BUILD)/a.out $(BUILD)/*.h $(BUILD)/*.json

.PHONY: all clean

