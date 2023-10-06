.PHONY:
build:
	dune build .

.PHONY:
test:
	dune test

.PHONY:
fmt:
	dune build @fmt --auto-promote
	clang-format -i ffi/*.cc ffi/*.h

.PHONY:
clean:
	dune clean
