.PHONY: build
build:
	dune build .

.PHONY: test
test:
	dune test

.PHONY: fmt
fmt:
	dune build @fmt --auto-promote
	clang-format -i ffi/*.cc ffi/*.h

.PHONY: clean
clean:
	dune clean
