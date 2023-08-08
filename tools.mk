R_ROOT:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
TOOLS_BIN:=$(R_ROOT)bin
SOLD:=$(TOOLS_BIN)/sold
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

TOOLS_VERSION:=0.71.0
UNAME_S:=$(shell uname -s)
ARC_PREFIX:=ever_tools
ARC_SUFFIX:=txz
TOOLS_ARCHIVE:=$(ARC_PREFIX)_$(TOOLS_VERSION)_$(UNAME_S).$(ARC_SUFFIX)
URL_PREFIX:=https\://github.com/tonlabs/TON-Solidity-Compiler/releases/download
TOOLS_URL:=$(URL_PREFIX)/$(TOOLS_VERSION)/$(TOOLS_ARCHIVE)
TOOLS_BINARIES:=$(SOLD) $(TOC) $(LINKER)

$(TOOLS_ARCHIVE):
	wget $(TOOLS_URL)
$(TOOLS_BIN):
	mkdir -p $@

tools: $(TOOLS_ARCHIVE) | $(TOOLS_BIN)
	tar -xJf $< -C $|
	$(foreach t,$(TOOLS_BINARIES),$t --version;)
	rm -f $<
