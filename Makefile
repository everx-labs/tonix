MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
include Makefile.common
include shell/Makefile
#include utils/Makefile
include boot/Makefile

# Contracts
AL:=AssemblyLine
O:=BootManager
CU:=CoreUtils
I:=CommandInterpreter
PRIME:=$(AL) $O $(CU) $I

INIT:=$(PRIME)
KEY:=~
RKEYS:=$(KEY)/k1.keys
VAL0:=15
TST:=tests
DBG:=debug

user?=root
VFS:=vfs
BIN:=$(VFS)/bin
DEV:=$(VFS)/dev
ETC:=$(VFS)/etc
PROC:=$(VFS)/proc
SYS:=$(VFS)/sys
TMP:=$(VFS)/tmp
USR:=$(VFS)/usr
UBIN:=$(USR)/bin
USH:=$(USR)/share
HOM:=$(VFS)/home/$(user)
HS:=$(HOM)/.sh_history
TBIN:=$(TMP)/bin
TSBIN:=$(TMP)/sbin
TSH:=$(TMP)/tosh

DIRS:=bin $(VFS) $(TMP) $(PROC) $(DEV) $(USR) $(USH) $(TSBIN) $(UBIN) $(HOM) $(TSH)

PHONY += all dirs cc tty tt deploy clean
all: cc

dirs:
	mkdir -p $(DIRS)
	echo / > $(PROC)/cwd

install: dirs cc
	$(TOC) config --url gql.custler.net

cc: $(patsubst %,$(BLD)/%.cs,$(BUILTINS))
	@true

$(BLD)/%.tvc: shell/$(SRC)/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
#$(BLD)/$I.tvc: boot/$(SRC)/$I.sol
#	$(SOLC) $< -o $(BLD)
#	$(LINKER) compile --lib $(LIB) $(BLD)/$I.code -o $@
$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

$(BLD)/$I_update_model_%.args: shell/$(BLD)/%.cs
	jq -R '{name:"$*",c:.}' $< >$@
$(BLD)/$I_update_model_%.ress: $(BLD)/$I_update_model_%.args
	$($I_c) update_model $(word 1,$^)

#uc: $(BLD)/$I.cs
#	$(eval args!=jq -R '{c:.}' $<)
#	$($I_c) upgrade_code '$(args)'

$(BLD)/%.ress: $(BLD)/%.cs
	$(eval args!=jq -R '{name:"$*",c:.}' $<)
	$($I_c) update_model '$(args)' >$@
	rm -f $(TSBIN)/$*.boc
ss: $(patsubst %,$(BLD)/%.ress,$(BUILTINS))
	echo $^

update_shell_model: $(patsubst %,$(BLD)/$I_update_model_%.ress,$(filter-out $(shell $($I_r) _images {} | jq -r '._images[].name'),$(shell cat etc/model.shell)))
	echo $^
s1: update_shell_model
etc/hosts.shell:
	$($I_r) etc_hosts {} | jq -j '.out' | sed 's/ *$$//' >$@
s3:
	rm -f etc/hosts.shell
	make etc/hosts.shell

bhf: $(patsubst %,$(USH)/%.help,$(HELP_TOPICS))
	echo $^
	rm -f $(USH)/builtin_help
	jq 'add' $^ >$(USH)/builtin_help

cmp: $(patsubst %,$(USH)/%.man,$(UTILS))
#cmp: $(patsubst %,$(USH)/%.man,man getent cat cut)
	echo $^
	rm -f $(USH)/man_pages
	jq 'add' $^ >$(USH)/man_pages

$(BLD)/%.abi.json: shell/$(SRC)/%.sol
	$(SOLC) $< --tvm-abi -o $(BLD)

$(USH)/%.help: $(TSBIN)/%.boc $(BLD)/%.abi.json
	./$(UBIN)/tosh builtin_help $*

$(USH)/%.man: $(TSBIN)/%.boc $(BLD)/%.abi.json
	./$(UBIN)/tosh command_help $*

$(USH)/builtin_help: $(patsubst %,$(USH)/%.help,$(HELP_TOPICS))
	jq 'add' $^ >$@

$(USH)/man_pages: $(patsubst %,$(USH)/%.man,$(UTILS))
	jq 'add' $^ >$@

t: tx bocs
	./$<
tty tt: bin/xterm
	./$<
mc: bin/mc
	./$<
bin/xterm: $(SRC)/xterm.c
	gcc $< -lreadline -o $@
bin/mc: $(SRC)/mc.c
	gcc $< -lreadline -o $@

.PHONY: $(PHONY)

V?=
#$(V).SILENT:
#.PHONY: no_targets__ list

.PHONY: list cc
.PRECIOUS: $(BLD)/*.tvc
list:
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
