MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory

# Tools directories
TOOLS_BIN:=~/bin
SOLC:=$(TOOLS_BIN)/solc
LIB:=$(TOOLS_BIN)/stdlib_sol.tvm
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

# Contracts
I:=CommandInterpreter
PRIME:=$I

UTILS:=ls du file stat namei cat colrm column cut expand grep head look rev tail tr unexpand paste wc readlink realpath env man whatis mkfs mke2fs dumpe2fs fsck mount umount losetup udevadm df findmnt mountpoint touch cp mv rm rmdir mkdir ln install groupadd groupdel groupmod useradd userdel usermod chfn newgrp lslogins finger who last fuser utmpdump ps whoami id hostname tfs tmpfs printenv basename dirname getent
HELP_TOPICS:=tosh help declare type builtin pwd read hash command export readonly alias unalias unset enable test cd dirs pushd popd echo complete ulimit shopt source jobs mapfile compgen exec set shift history getopts eilish
BUILTINS:=$(HELP_TOPICS) $(UTILS)

INIT:=$(PRIME)
#INIT:=$I

user?=root

BOOTDIR:=
#VFS:=../vfs
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
#TSH:=$(TMP)/sh
TSH:=$(TMP)/tosh

DIRS:=bin $(VFS) $(PROC) $(DEV)

PHONY += all ccs

SRC:=src
BLD:=build

ccs: $(patsubst %,$(BLD)/%.cs,$(BUILTINS))
	@true

install: $(patsubst %,$(BLD)/%.cs,$(BUILTINS)) $(patsubst %,$(BLD)/%.abi.json,$(BUILTINS))
	cp $^ ../$(BLD)

$(BLD)/%.tvc: $(SRC)/%.sol
	$(SOLC) $< -o $(BLD)
	$(LINKER) compile --lib $(LIB) $(BLD)/$*.code -o $@
$(BLD)/%.cs: $(BLD)/%.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@

define t-call
$1_a=$$(shell grep -w $1 etc/hosts.boot | cut -f 1)
$$(eval $1_r=$(TOC) -j run $$($1_a) --abi ../boot/$(BLD)/$1.abi.json)
$$(eval $1_c=$(TOC) call $$($1_a) --abi ../boot/$(BLD)/$1.abi.json)
endef

$(foreach c,$(INIT),$(eval $(call t-call,$c)))

define t-shell
$(TSH)/$1_%.out: $(TSBIN)/$1.boc shell/$(BLD)/$1.abi.json $(TSH)/$1_%.args
	$(TOC) -j run --boc $$(word 1,$$^) --abi $$(word 2,$$^) $$* $$(word 3,$$^) >$$@
endef

$(foreach c,$(BUILTINS),$(eval $(call t-shell,$c)))

$(TSBIN)/%.boc: etc/hosts.shell
	$(eval aa!=grep -w $* $< | cut -f 1)
	$(TOC) account $(aa) -b $@

$(TSBIN)/acc/%.boc: etc/hosts.shell
	$(eval aa!=grep -w $* $< | cut -f 1)
	$(TOC) account $(aa) -b $@

hb:
	$($I_r) etc_hosts {} | jq -j '.out'
	$($I_r) models {} | jq -j '.out'

# SH processing start

bocs: $(patsubst %,$(TSBIN)/%.boc,$(BUILTINS))
	@true

SCR:=$(TSH)/script

$(TSH)/tosh_process_input.out: $(TMP)/i_input $(BLD)/tosh.abi.json bocs
	$(UBIN)/tosh process_input $<

$(TSH)/tosh_read_profile.out: $(ETC)/profile $(BLD)/tosh.abi.json bocs
	$(UBIN)/tosh read_profile $<

prof: $(TSH)/tosh_read_profile.out
	@true

$(TSH)/builtin_main.out: $(TMP)/i_input $(BLD)/builtin.abi.json bocs
	$(UBIN)/builtin main $<

#$(TSH)/tosh_read_command.out: $(TMP)/i_input $(BLD)/tosh.abi.json bocs
#	$(UBIN)/builtin builtin_exec read $<
#	$(UBIN)/tosh read_command $<

$(TSH)/tosh_exec_command.out: $(TSH)/tosh_interpret_command.out
	$(UBIN)/tosh exec_command

#$(TSH)/stdout: $(TSH)/tosh_read_profile.out
#$(TSH)/stdout: $(TSH)/tosh_read_command.out
#$(TSH)/stdout: $(TSH)/tosh_interpret_command.out
#	jq -r '.env[24]' $< >$@
#	jq -r '.env[25]' $< >$@
#	jq -r '.env[]' $<
$(TSH)/stdout: $(SCR)
	chmod +x $(SCR);./$(SCR);
#	jq -r '.env[23]' $<

#$(TSH)/tosh_read_command.out: $(TSH)/script_b
$(TSH)/tosh_main.out: $(TSH)/script_b
#	$(UBIN)/builtin builtin_exec read $<
	chmod +x $<;./$<;

#$(TSH)/script: $(TSH)/tosh_read_command.out
#$(TSH)/script: $(TSH)/tosh_read_command.out
$(TSH)/script: $(TSH)/tosh_main.out
#	jq -r '.env[21]' $< >$@
	jq -r '.env[26]' $< >$@
$(TSH)/script_b: $(TSH)/builtin_main.out
	jq -r '.env[21]' $< >$@

SH: $(TSH)/stdout
	@true

tosh: bocs
	$(UBIN)/tosh
#####

.PHONY: $(PHONY)
.PRECIOUS: $(TSBIN)/*.boc $(BLD)/*.tvc

V?=
#$(V).SILENT:
