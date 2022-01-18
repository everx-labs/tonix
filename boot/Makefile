MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
#include ../Makefile.common

# Contracts
#AL:=AssemblyLine
#O:=BootManager
CU:=CoreUtils
I:=CommandInterpreter
#PRIME:=$(AL) $O $(CU) $I
#PRIME:=$(CU) $I
PRIME:=$I

INIT:=$(PRIME)
#INIT:=$I
KEY:=~
RKEYS:=$(KEY)/k1.keys

PHONY += ccb deploy clean
all: ccb

TOOLS_BIN:=~/bin
SOLC:=$(TOOLS_BIN)/solc
LIB:=$(TOOLS_BIN)/stdlib_sol.tvm
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

SRC:=src
BLD:=build

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

ccb: $(patsubst %,$(BLD)/%.cs,$(INIT))
#	$(du_) $^
	@true
deploy: $(DEPLOYED)
	-cat $^

$(BLD)/%.tvc: $(SRC)/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@

$(BLD)/%.shift: $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS)
	$(TOC) genaddr $< $(word 2,$^) --setkey $(word 3,$^) | grep "Raw address:" | sed 's/.* //g' >$@
$(BLD)/%.cargs:
	$(file >$@,{})
$(BLD)/%.deployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL0))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@

$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

repo: $(DEPLOYED)
	$(foreach c,$^,printf "%s %s\n" $c `grep "deployed at address" $^ | cut -d ' ' -f 5`;)

define t-call
$1_a=$$(shell grep -w $1 etc/hosts.boot | cut -f 1)
$$(eval $1_r=$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json)
$$(eval $1_c=$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json)
endef

$(foreach c,$(INIT),$(eval $(call t-call,$c)))

n?=22
k?=44
init_x:
	$($I_c) init_x '{"n":$n,"k":$k}'


.PHONY: $(PHONY)

V?=
#$(V).SILENT:
#.PHONY: no_targets__ list

.PHONY: list cc
listb:
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'