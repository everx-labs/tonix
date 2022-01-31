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

SRC:=src
BLD:=build
RKEYS:=~/k1.keys
VAL0:=15

# Contracts
I:=Repo
PRIME:=$I

UTILS:=basename cat colrm column cp cut df dirname du dumpe2fs env expand file findmnt finger fsck fuser getent grep groupadd groupdel groupmod groups head hostname id install last ln login look losetup ls lsblk lslogins man mkdir mke2fs mkfs mknod mount mountpoint mv namei newgrp paste pathchk printenv ps readlink realpath rev rm rmdir stat tail tfs tmpfs touch tr udevadm umount uname unexpand useradd userdel usermod utmpdump wc whatis who whoami
HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export getopts hash help jobs mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
BUILTINS:=$(HELP_TOPICS) $(UTILS)

INIT:=$(PRIME)

BIN:=bin
TMP:=tmp
RUN:=run
USH:=usr/share
LOG:=var/log
DIRS:=$(BIN) $(TMP) $(RUN) $(USH) $(LOG)

dirs:
	mkdir -p $(DIRS)

cc: $(patsubst %,$(BLD)/%.cs,$(BUILTINS))
	@true

install: dirs cc
	echo Tonix has been installed successfully
	$(TOC) config --url rfld-dapp01.ds1.itgold.io

TOOLS_MAJOR_VERSION:=0.56
TOOLS_MINOR_VERSION:=0
TOOLS_VERSION:=$(TOOLS_MAJOR_VERSION).$(TOOLS_MINOR_VERSION)
TOOLS_ARCHIVE:=tools_$(TOOLS_MAJOR_VERSION)_$(UNAME_S).txz
TOOLS_URL:=https\://github.com/tonlabs/TON-Solidity-Compiler/releases/download/$(TOOLS_VERSION)/$(TOOLS_ARCHIVE)
TOOLS_BINARIES:=$(LIB) $(SOLC) $(LINKER) $(TOC)
$(TOOLS_BINARIES):
	mkdir -p $(TOOLS_BIN)
	rm -f $(TOOLS_ARCHIVE)
	wget $(TOOLS_URL)
	tar -xzf $(TOOLS_ARCHIVE) -C $(TOOLS_BIN)

tools: $(TOOLS_BINARIES)
	$(foreach t,$(wordlist 2,4,$^),$t --version;)

$(BLD)/%.tvc: $(SRC)/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

define t-call
$1_a=$$(shell grep -w $1 etc/hosts.boot | cut -f 1)
$$(eval $1_r=$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json)
$$(eval $1_c=$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json)
endef

$(foreach c,$(INIT),$(eval $(call t-call,$c)))

$(BIN)/%.boc: etc/hosts.shell
	$(eval aa!=grep -w $* $< | cut -f 1)
	$(TOC) account $(aa) -b $@

report:
	$($I_r) models {} | jq -j '.out'

bocs: $(patsubst %,$(BIN)/%.boc,$(BUILTINS))
	@true

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

ccb: $(patsubst %,$(BLD)/%.cs,$(INIT))
	@true
deploy: $(DEPLOYED)
	-cat $^

$(BLD)/%.shift: $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS)
	$(TOC) genaddr $< $(word 2,$^) --setkey $(word 3,$^) | grep "Raw address:" | sed 's/.* //g' >$@
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

uc: $(BLD)/$I.cs
	$(eval args!=jq -R '{c:.}' $<)
	$($I_c) upgrade_code '$(args)'

$(BLD)/%.ress: $(BLD)/%.cs
	$(eval args!=jq -R '{name:"$*",c:.}' $<)
	$($I_c) update_model '$(args)' >$@
	rm -f $(BIN)/$*.boc
ss: $(patsubst %,$(BLD)/%.ress,$(BUILTINS))
	echo $^

etc/hosts.shell:
	$($I_r) etc_hosts {} | jq -j '.out' | sed 's/ *$$//' >$@
hosts:
	rm -f etc/hosts.shell
	make etc/hosts.shell

bhf: $(patsubst %,$(USH)/%.help,$(HELP_TOPICS))
	rm -f $(USH)/builtin_help
	jq 'add' $^ >$(USH)/builtin_help

cmp: $(patsubst %,$(USH)/%.man,$(UTILS))
	rm -f $(USH)/man_pages
	jq 'add' $^ >$(USH)/man_pages

$(USH)/%.help: $(BIN)/%.boc $(BLD)/%.abi.json
	./tosh builtin_help $*
$(USH)/%.man: $(BIN)/%.boc $(BLD)/%.abi.json
	./tosh command_help $*
$(USH)/builtin_help: $(patsubst %,$(USH)/%.help,$(HELP_TOPICS))
	jq 'add' $^ >$@
$(USH)/man_pages: $(patsubst %,$(USH)/%.man,$(UTILS))
	jq 'add' $^ >$@

tty tt: tx bocs
	./$<
bin/dir_list: src/dir_list.c
	gcc $< -o $@ -lmenu -lncurses
dl: bin/dir_list tmp/dirs_builtin_read_fs.out
	./$< "`jq -rj '.res' $(word 2,$^)`"

V?=
#$(V).SILENT:

.PHONY: list cc ss hosts tt tty cmp bhf
.PRECIOUS: $(BIN)/*.boc
list:
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
