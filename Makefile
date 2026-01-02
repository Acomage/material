.PHONY: all build clean rebuild

LEAN_CC := clang

FUTHARK_BUILD_DIR := Material/Extract/futhark/build
LEAN_BUILD_DIR := .lake/build

all: build

build:
	LEAN_CC=$(LEAN_CC) lake build -v

clean:
	lake clean
	rm -rf $(FUTHARK_BUILD_DIR)/*

rebuild: clean build
