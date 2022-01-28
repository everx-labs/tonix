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

UTILS:=basename cat chfn colrm column cp cut df dirname du dumpe2fs env expand file findmnt finger fsck fuser getent grep groupadd groupdel groupmod groups head hostname id install last ln look losetup ls lslogins man mkdir mke2fs mkfs mknod mount mountpoint mv namei newgrp paste pathchk printenv ps readlink realpath rev rm rmdir stat tail tfs tmpfs touch tr udevadm umount uname unexpand useradd userdel usermod utmpdump wc whatis who whoami
HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export getopts hash help jobs mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
BUILTINS:=$(HELP_TOPICS) $(UTILS)

INIT:=$(PRIME)

user?=root

BOOTDIR:=
VFS:=vfs
#BIN:=$(VFS)/bin
DEV:=$(VFS)/dev
ETC:=$(VFS)/etc
PROC:=$(VFS)/proc
SYS:=$(VFS)/sys
TMP:=$(VFS)/tmp
USR:=$(VFS)/usr
UBIN:=bin
USH:=$(USR)/share
HOM:=$(VFS)/home/$(user)
HS:=$(HOM)/.sh_history
#TBIN:=$(TMP)/bin
#TSBIN:=$(TMP)/sbin
TBIN:=bin
TSBIN:=bin
TSH:=$(TMP)/tosh
VAR:=$(VFS)/var
LOG:=$(VAR)/log

DIRS:=bin $(VFS) $(PROC) $(DEV)

PHONY += all ccs

SRC:=src
BLD:=build

ccs: $(patsubst %,$(BLD)/%.cs,$(BUILTINS))
	@true

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

report:
	$($I_r) models {} | jq -j '.out'

# SH processing start

bocs: $(patsubst %,$(TSBIN)/%.boc,$(BUILTINS))
	@true

tosh: bocs
	$(UBIN)/tosh
#####

.PHONY: $(PHONY)
.PRECIOUS: $(TSBIN)/*.boc $(BLD)/*.tvc

V?=
#$(V).SILENT:
