# --------------------------------------------------------
# Compiler settings
# --------------------------------------------------------
CC      := clang
ISPC    := ispc
FUTHARK := futhark

CFLAGS  := -O3 -march=native -mtune=native -ffast-math -fstrict-aliasing \
           -funroll-loops -fomit-frame-pointer -DNDEBUG

LDFLAGS := -lm -lpng -lturbojpeg

BUILD   := ./src/Extract/futhark/build
SRC     := ./src/Extract/futhark/src

all: $(BUILD)/extract.o $(BUILD)/extract.kernels.o

$(BUILD)/extract.c $(BUILD)/extract.kernels.ispc: $(SRC)/celebi.fut $(SRC)/wu.fut $(SRC)/wsmeans.fut $(SRC)/color.fut $(SRC)/extract.fut $(SRC)/hct.fut $(SRC)/score.fut
	$(FUTHARK) ispc --library $(SRC)/extract.fut -o $(BUILD)/extract

$(BUILD)/extract.kernels.o: $(BUILD)/extract.kernels.ispc
	$(ISPC) -o $@ $< --addressing=32 --pic --woff -O3

$(BUILD)/extract.o: $(BUILD)/extract.c
	$(CC) $(CFLAGS) -c $(BUILD)/extract.c -o $@

# Misc
clean:
	rm -rf $(BUILD)/*.o $(BUILD)/*.c $(BUILD)/*.ispc $(BUILD)/a.out $(BUILD)/*.h $(BUILD)/*.json

.PHONY: all clean
