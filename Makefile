R_ROOT:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

tools:
	$(MAKE) -f tools.mk tools

.PHONY: list

