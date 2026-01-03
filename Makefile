.PHONY: all build clean rebuild

LEAN_CC := clang

FUTHARK_BUILD_DIR := Material/Extract/futhark/build
LEAN_BUILD_DIR := .lake/build

all: build

$(FUTHARK_BUILD_DIR)/libcolor_extract.a:
	cd Material/Extract/futhark && cmake -S . -B ./build -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ && cmake --build ./build

build:$(FUTHARK_BUILD_DIR)/libcolor_extract.a
	LEAN_CC=$(LEAN_CC) lake build -v

clean:
	lake clean
	rm -rf $(FUTHARK_BUILD_DIR)/*

rebuild: clean build
