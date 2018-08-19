.PHONY: all
all:
	dune build @install -j auto --profile dev

.PHONY: clean
clean:
	dune clean
