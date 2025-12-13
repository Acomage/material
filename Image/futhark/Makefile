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
$(BUILD)/extract.c $(BUILD)/extract.kernels.ispc: $(SRC)/celebi.fut $(SRC)/wu.fut $(SRC)/wsmeans.fut $(SRC)/color.fut $(SRC)/extract.fut $(SRC)/hct.fut $(SRC)/score.fut
	$(FUTHARK) ispc --library $(SRC)/extract.fut -o $(BUILD)/extract

# 2. Compile ISPC kernels
$(BUILD)/extract.kernels.o: $(BUILD)/extract.kernels.ispc
	$(ISPC) -o $@ $< --addressing=32 --pic --woff -O3

# 3. Final binary: clang + your C files + ISPC object
$(BUILD)/a.out: $(BUILD)/extract.c $(SRC)/quantize.c $(BUILD)/extract.kernels.o $(SRC)/load_image.h
	$(CC) $(CFLAGS) $(BUILD)/extract.c $(SRC)/quantize.c $(BUILD)/extract.kernels.o \
		$(LDFLAGS) -o $@

# Misc
clean:
	rm -rf $(BUILD)/*.o $(BUILD)/*.c $(BUILD)/*.ispc $(BUILD)/a.out $(BUILD)/*.h $(BUILD)/*.json

.PHONY: all clean
