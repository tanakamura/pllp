all: tests hello_linker
CFLAGS=-g -Wall
hello_linker: hello_linker.c

tests: tests/2file

tests/2file:
	$(MAKE) -C tests/2file


.PHONY: tests/2file

