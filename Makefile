R_ROOT:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

tools:
	$(MAKE) -f tools.mk tools

triage: tools
	$(MAKE) -C opt/triage try1

.PHONY: list

