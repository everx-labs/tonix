R_ROOT:=$(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
export
.ONESHELL:
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
#NET:=rfld
#NET:=fld
NET:=dev

GIVER:=Novi
VAL0:=15
VAL1:=1
#TOOLS_BIN:=~/bin/0.67.1
TOOLS_BIN:=$(R_ROOT)/bin
RKEYS:=$(R_ROOT)/k1.keys
# Tools directories
SOLD:=$(TOOLS_BIN)/sold
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli
BIN:=bin
BLD:=build
ETC:=etc
TMP:=tmp
URL_dev:=devnet.evercloud.dev
URL_fld:=gql.custler.net
URL_rfld:=rfld-dapp.itgold.io
PID_dev:=2e786c9575af406fa784085c88b5e7e3
AK_dev:=38f728004a4b40e2a8aa30f8fee45346
URL:=$(URL_$(NET))
PID:=$(PID_$(NET))
AK:=$(AK_$(NET))
PAK_dev=--project_id $(PID) --access_key $(AK)
PAK=$(PAK_$(NET))

#_pay=$(TOC) -c $(R_ROOT)/etc/$(GIVER).$(NET).conf callx -m sendTo --dest $1 --val $2
1?=
2?=
define _pay
	$(TOC) -c $(R_ROOT)/etc/$(GIVER).$(NET).conf callx --abi $(R_ROOT)/etc/$(GIVER).abi.json -m sendTo --dest $1 --val $2
endef

H?=
CTX?=
INIT?=$H
DEPLOYED=$(patsubst %,$(BLD)/%.ployed,$(INIT))
INSTALLED=$(patsubst %,$(BLD)/%.installed,$(INIT))
CONFD=$(patsubst %,$(ETC)/%.conf,$(CTX))
CCS=$(patsubst %,$(BLD)/%.cs,$(CTX))
CSS=$(patsubst %,$(BLD)/%.tvc,$(CTX))
ASM=$(patsubst %,$(BLD)/%.code,$(CTX))
ABI=$(patsubst %,$(BLD)/%.abi.json,$(CTX))
DIRS:=$(BLD) $(ETC) $(TMP)
INC_PATH?=
all: dirs config cc

$(DIRS):
	mkdir -p $@
dirs:
	mkdir -p $(DIRS)
cs: $(CCS) | $(DIRS) ## obtain a cell containing the smart-contract code
	@true
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

$(BLD)/%.installed: $(BLD)/%.shift $(BLD)/%.abi.json
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 2,$^) --is_json true --balance_in_tons true >$@
$(BLD)/%.tvc: %.sol
#	$(SOLD) $< $(foreach i,$(INC_PATH),-I $i) -O $(BLD)
	$(SOLD) $< --base-path . $(foreach i,$(INC_PATH),-i $i) -o $(BLD)
$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

$(BLD)/%.shift: $(BLD)/%.tvc $(RKEYS)
	$(TOC) -j genaddr $< --setkey $(word 2,$^) | jq -r '.raw_address' >$@
#$(BLD)/%.cargs:
#	$(file >$@,{})
$(BLD)/$H.ployed: VAL1 = 10
$(BLD)/%.ployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS)
	$(call _pay,$(file < $<),$(VAL1))
	$(TOC) -u $(URL) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) {} >$@
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 3,$^) --is_json true --balance_in_tons true $(PAK)
	$(TOC) config alias add --addr $(file <$<) --abi $(word 3,$^) $*

dd_%: $(BLD)/%.tvc
	$(eval a!=$(TOC) -j genaddr $< --setkey $(RKEYS) | jq -r '.raw_address')
	$(call _pay,$a,$(VAL1))
	$(TOC) deploy $< --abi $(BLD)/$*.abi.json --sign $(RKEYS) {}
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --addr $a --abi $(BLD)/$*.abi.json --is_json true --balance_in_tons true --project_id 2e786c9575af406fa784085c88b5e7e3 --access_key 38f728004a4b40e2a8aa30f8fee45346
name?=
val?=15
pay: $(ETC)/$(name).conf
	$(call _pay,`jq -r '.config.addr' $<`,$(val))
up: $(BLD)/$(name).cs $(ETC)/$(name).conf
	$(TOC) -c $(word 2,$^) callx -m uc --c $(file <$<)
up_%: $(BLD)/%.cs $(ETC)/%.conf
	$(TOC) -c $(word 2,$^) callx -m uc --c $(file <$<)
hconf_%: $(BLD)/%.shift $(BLD)/%.abi.json
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(word 2,$^) --is_json true --balance_in_tons true
$(TMP)/%.tvc: $(TMP)/%.boc
	$(TOC) decode account boc $< -d $@
dump_%: $(TMP)/%.tvc $(BLD)/%.abi.json
	$(TOC) decode account data --abi $(word 2,$^) --tvc $<
$(TMP)/%.boc: $(ETC)/%.conf
	$(TOC) account `jq -r .config.addr $<` -b $@
dump2_%: $(TMP)/%.boc $(BLD)/%.abi.json
	$(TOC) decode account boc $<

remap_%: $(ETC)/%.conf $(BLD)/%.abi.json
	$(TOC) config alias add --addr `jq -r .config.addr $<` --abi $(word 2,$^) $*

#remap: $(patsubst %,$(ETC)/%.conf,$(CTX))
#	$(foreach a,$^,$(MAKE) remap_$a;)

remap:
	$(foreach a,$(CTX),$(MAKE) remap_$a;)
	$(TOC) config alias print

SHX?=e.sh
$(TMP)/dev.tar.xz: Makefile $(SHX) $(patsubst %,%.sol,$(CTX))
#$(TMP)/%.tar.xz: Makefile $(SHX) $(patsubst %,$(BLD)/%.abi.json,$(CTX)) $(patsubst %,$(ETC)/%.conf,$(CTX))
$(TMP)/%.tar.xz: Makefile $(SHX) $(BLD)/%.abi.json $(ETC)/%.conf
	tar cJvf $@ $^
#pack_%: $(TMP)/%.tar.xz
#$(TMP)/%.tar.xz:
#	tar cJvf $@ $^

define t-run
R$1=$(TOC) -c $(ETC)/$1.conf runx -m
r$1=$(TOC) runx --addr $1 -m
endef

$(foreach a,$(CTX),$(eval $(call t-run,$a)))

_fa=$(foreach c,$(CTX),$(call $1,$c);)
_ping=$(TOC) account `jq -r .config.addr etc/$1.conf` | jq -c .balance | xargs echo $1:
ping:
	echo $(URL)
	$(call _fa,_ping)

list:   ## List the existing targets
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
