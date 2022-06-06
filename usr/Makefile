MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
UNAME_S:=$(shell uname -s)

# Tools directories
TOOLS_BIN:=~/bin
SOLC:=$(TOOLS_BIN)/solc
LIB:=$(TOOLS_BIN)/stdlib_sol.tvm
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

GIVER:=Novi
_pay=$(TOOLS_BIN)/$(GIVER)/s4.sh $1 $2
#_pay=$(TOOLS_BIN)/$(GIVER)/s2.sh $1 $2

SRC:=src
BLD:=build
RKEYS:=~/k1.keys
VAL0:=15

# Contracts
I:=Repo
S:=startup

#I:=startup
#PRIME:=$I
#H:=host
#PRIME:=$S $I
PRIME:=$I
#H:=hive

BINUTILS:=cat cp cut df echo ln ls mkdir mv ps pwd realpath rm rmdir test eilish
#UTILS:=basename cat colrm column cp cut df dirname du dumpe2fs env expand file findmnt finger fsck fuser getent grep groupadd groupdel groupmod groups head hostname id last ln login look losetup ls lsblk lslogins man mkdir mke2fs mkfs mount mountpoint mv namei newgrp paste pathchk printenv ps readlink realpath rev rm rmdir stat tail tfs tmpfs touch tr umount uname unexpand useradd userdel usermod utmpdump wc whatis who whoami lsof explain reboot sdz vnp hive umm vmstat vmm mdb diff mddb md2 patch
#OPT:=dist adc jury
#HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export getopts hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
#DEVICES:=null
#FILES:=motd group procfs
#KI:=core zone_misc corev2 kview corev3 kview2 stg0 bringup bringup2 bringup3 kview3 bringup4 zones_viewer patch_zone zones_host stg1 stg2 stg3 file_host call_proxy stg4 stg5 stg41 stg42 patch3 file_index stg44 GSV idx4
#HOSTS:=uma_startup
#BUILTINS:=$(HELP_TOPICS) $(UTILS) $(DEVICES)
#BUILTINS:=$(HELP_TOPICS) $(UTILS) $(HOSTS)
#BUILTINS:=$S
SUB:=bin
S:=$(BINUTILS)

INIT:=$(PRIME)

BIN:=bin
TMP:=tmp
RUN:=run
USH:=usr/share
LOG:=var/log
BLD:=build
DIRS:=$(BIN) $(TMP) $(RUN) $(USH) $(LOG) $(BLD)

#binutils: $(patsubst %,$(BIN)/%.cs,$S)

SRCDIR?=	${.CURDIR}
.PATH: ${SYSDIR}/libkern
SRCS+=  explicit_bzero.c crc32_libkern.c

b: $(patsubst %,$(BLD)/%.cs,$S)
	$(MAKE) -C $(SRC)/bin
dirs:
	mkdir -p $(DIRS)

#cc: $(SUB)
cc:  $(patsubst %,$(BLD)/%.cs,$S)
#	export $(BLD)
	$(foreach d,$^,cd $(SRC)/$d && make cc BLD=$(BLD))

config:
#$	$(TOC) config --url rfld-dapp01.ds1.itgold.io
	$(TOC) config --url gql.custler.net

#$(BLD)/%.tvc: $(SRC)/%.sol
$(BLD)/%.tvc: $(SRC)/dev/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.tvc: $(SRC)/bin/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.tvc: $(SRC)/uma/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.tvc: $(SRC)/opt/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.tvc: $(SRC)/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.dbg: $(BLD)/%.code
	$(LINKER) compile --lib $(LIB) $< --debug-map $(BLD)/$*.dbg -o $@
$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

define t-addr-boot
$1_a=$$(shell grep -w $1 etc/hosts.0 | cut -f 1)
endef

define t-call
$$(eval $1_r=$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json)
$$(eval $1_dr=$(TOC) debug run $$($1_a) --abi $(BLD)/$1.abi.json --debug-map $(BLD)/$1.dbg)
$$(eval $1_c=$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json)
endef

$(foreach c,$(INIT),$(eval $(call t-addr-boot,$c)))
#$(foreach c,$H $B,$(eval $(call t-addr-hive,$c)))
#$(foreach c,$(INIT) $(DEVICES) $(FILES),$(eval $(call t-call,$c)))

$(BIN)/$S.boc: etc/hosts.0
	$(eval aa!=grep -w $S $< | cut -f 1)
	$(TOC) account $(aa) -b $@
$(BIN)/%.boc: etc/hosts.1
	$(eval aa!=grep -w $* $< | cut -f 1)
	$(TOC) account $(aa) -b $@

report:
	$($I_r) models {} | jq -j '.out'

ru:
	$($H_r) models {} | jq -j '.out'

bocs: $(patsubst %,$(BIN)/%.boc,$S)
	@true

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

ccb: $(patsubst %,$(BLD)/%.cs,$(INIT))
	@true
deploy: $(DEPLOYED)
	-cat $^

$(BLD)/%.shift: $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS)
	$(TOC) genaddr $< --abi $(word 2,$^) --setkey $(word 3,$^) | grep "Raw address:" | sed 's/.* //g' >$@
$(BLD)/%.cargs:
	$(file >$@,{})
$(BLD)/%.deployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL0))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@

repo: $(DEPLOYED)
	$(foreach c,$^,printf "%s %s\n" $c `grep "deployed at address" $^ | cut -d ' ' -f 5`;)

n?=22
k?=44
init_x:
	$($I_c) init_x '{"n":$n,"k":$k}'

uc0: $(BLD)/$I.cs
	$(eval args!=jq -R '{c:.}' $<)
	$($I_c) upgrade_code '$(args)'

ss: $(patsubst %,$(BLD)/%.ress,$S)
	@true

name?=
s_add: $(BLD)/$(name).cs
	$(eval args!=jq -R '{index:0,name:"$(name)",c:.}' $<)
	$($I_c) update_model_at_index '$(args)'
add_all: $(patsubst %,$(BLD)/%.as,$S)
	echo $^
$(BLD)/%.as: $(BLD)/%.cs
	$(eval args!=jq -R '{index:0,name:"$*",c:.}' $<)
	$($I_c) update_model_at_index '$(args)' >$@

k?=1
n?=1
$(BLD)/%.ress: $(BLD)/%.cs
	$(eval index!=grep -nw $* etc/hosts.1 | cut -d ':' -f 1)
	$(eval args!=jq -R '{index:$(index),name:"$*",c:.}' $<)
	$($I_c) update_model_at_index '$(args)' >$@
	rm -f $(BIN)/$*.boc

etc/hosts.1:
	$($I_r) etc_hosts {} | jq -j '.out' | sed 's/ *$$//' >$@
hosts:
	rm -f etc/hosts.1
	make etc/hosts.1

V?=
#$(V).SILENT:

.PHONY: list cc ss hosts tt tty cmp bhf
.PRECIOUS: $(BIN)/*.boc
