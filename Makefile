R_ROOT:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

tools:
	$(MAKE) -f tools.mk tools

triage: tools
	$(MAKE) -C opt/triage dirs try1

.PHONY: list

