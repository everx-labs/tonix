R_ROOT:=$(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
export
.ONESHELL:
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory

### Network config
U_dev:=devnet.evercloud.dev
U_fld:=gql.custler.net
U_rfld:=rfld-dapp.itgold.io
U_venom:=venom-testnet.evercloud.dev

NET?=rfld
URL:=$(U_$(NET))

TOOLS_BIN?=$(R_ROOT)/bin
# Tools directories
SOLD?=$(TOOLS_BIN)/sold
LINKER?=$(TOOLS_BIN)/tvm_linker
TOC?=$(TOOLS_BIN)/tonos-cli
BIN?=bin
BLD?=build
ETC?=etc
TMP?=tmp

### Payment utilities
RKEYS?=$(R_ROOT)/$(ETC)/k1.keys
GIVER?=Novi
VAL?=1
#_pay=$(TOC) -c $(R_ROOT)/etc/$(GIVER).$(NET).conf callx -m sendTo --dest $1 --val $2
1?=
2?=
define _pay
	$(TOC) -c $(R_ROOT)/$(ETC)/$(GIVER).$(NET).conf callx --abi $(R_ROOT)/$(ETC)/$(GIVER).abi.json -m sendTo --dest $1 --val $2
endef

CTX?=
DEPLOYED=$(patsubst %,$(BLD)/%.ployed,$(CTX))
INSTALLED=$(patsubst %,$(BLD)/%.installed,$(CTX))
CONFD=$(patsubst %,$(ETC)/%.conf,$(CTX))
CSS=$(patsubst %,$(BLD)/%.tvc,$(CTX))
DIRS?=$(BLD) $(ETC) $(TMP)
INC_PATH?=

### Targets

all: dirs config cc

$(DIRS):
	mkdir -p $@
dirs:
	mkdir -p $(DIRS)
cc: $(CSS) | $(DIRS) ## compile source contracts to generate the initial state
	@true
clean:
	rm -f $(BLD)/*.cs
deploy: $(DEPLOYED) ## Deploy a set of contracts marked as initial
	-cat $^
install: $(INSTALLED)
config:
	$(TOC) config --url $(URL) --is_json true --balance_in_tons true $(PAK)
conf: $(CONFD)
	-cat $^

### Recipes

$(BLD)/%.installed: $(BLD)/%.shift $(BLD)/%.abi.json  ## Configure already deployed contracts
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 2,$^) --is_json true --balance_in_tons true >$@
$(BLD)/%.tvc: %.sol  ## Compile smart-contract source to a binary image
#	$(SOLD) $< $(foreach i,$(INC_PATH),-I $i) -O $(BLD)  ## old-fashioned compilation recipe
	$(SOLD) $< --base-path . $(foreach i,$(INC_PATH),-i $i) -o $(BLD)
$(BLD)/%.cs: $(BLD)/%.tvc  ## Extract code cell from a binary image
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@
$(BLD)/%.shift: $(BLD)/%.tvc $(RKEYS) ## Calculate future address in the blockchain for subsequent deployment
	$(TOC) -j genaddr $< --setkey $(word 2,$^) | jq -r '.raw_address' >$@
$(BLD)/%.ployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) ## Pre-pay and deploy contract to the blockchain
	$(call _pay,$(file < $<),$(VAL))
	$(TOC) -u $(URL) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) {} >$@
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 3,$^) --is_json true --balance_in_tons true
	$(TOC) config alias add --addr $(file <$<) --abi $(word 3,$^) $*

$(TMP)/%.boc: $(ETC)/%.conf ## Fetch the current smart-contract state to a local directory
	$(TOC) account `jq -r .config.addr $<` -b $@
$(TMP)/%.tvc: $(TMP)/%.boc  ## Extract account information from a cached state
	$(TOC) decode account boc $< -d $@

name?=
val?=10
pay: $(ETC)/$(name).conf
	$(call _pay,`jq -r '.config.addr' $<`,$(val))
up: $(BLD)/$(name).cs $(ETC)/$(name).conf
	$(TOC) -c $(word 2,$^) callx -m uc --c $(file <$<)

pay_%: $(ETC)/%.conf
	$(call _pay,`jq -r '.config.addr' $<`,$(val))
ploy_%: $(BLD)/%.ployed
	@true
up_%: $(BLD)/%.cs $(ETC)/%.conf
	$(TOC) -c $(word 2,$^) callx -m uc --c $(file <$<)
hconf_%: $(BLD)/%.shift $(BLD)/%.abi.json
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 2,$^) --is_json true --balance_in_tons true
dump_%: $(TMP)/%.tvc $(BLD)/%.abi.json
	$(TOC) decode account data --abi $(word 2,$^) --tvc $<

define t-run
R$1=$(TOC) -c $(ETC)/$1.conf runx -m
r$1=$(TOC) runx --addr $1 -m
endef

$(foreach a,$(CTX),$(eval $(call t-run,$a)))

_fa=$(foreach c,$(CTX),$(call $1,$c);)
_ping=$(TOC) account `jq -r .config.addr $(ETC)/$1.conf` | jq -c .balance | xargs echo $1:
ping:
	echo $(URL)
	$(call _fa,_ping)

list:   ## List the existing targets
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
