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

SRC:=usr/src
BLD:=build
RKEYS:=~/k1.keys
VAL0:=15

# Contracts
I:=Repo
#S:=startup

#I:=startup
#PRIME:=$I
#H:=host
#PRIME:=$S $I
PRIME:=$I
#H:=hive

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

#BINUTILS:=cat cp cut df echo ln ls mkdir mv ps pwd realpath rm rmdir test eilish
SRCTOP?=.
SUB:=bin

INIT:=$(PRIME)

BIN:=bin
#TMP:=tmp
TMP:=$(CURDIR)/tmp
RUN:=run
USR:=usr
USH:=$(USR)/share
USRC:=$(USR)/src
UOBJ:=$(USR)/obj
LOG:=var/log
DIRS:=$(BIN) $(TMP) $(RUN) $(USH) $(LOG)

dirs:
	mkdir -p $(DIRS)

ETC_HOSTS:=$(CURDIR)/etc/hosts.1
BINU:=cat cp df echo ln ls mkdir mv pwd realpath rm rmdir test eilish
SBINU:=fsck mount reboot umount
BOOTU:=Repo
USR.BINU:=alias basename chfn colrm column cut diff dirname du env expand file findmnt finger fuser getent grep groups head hostid hostname id last login look lsblk lslogins lsof man mountpoint namei newgrp paste patch pathchk printenv ps readlink rev stat tail touch tr uname unexpand wc whatis who whoami
USR.SBINU:=dumpe2fs groupadd groupdel groupmod mke2fs mkfs useradd userdel usermod
SHB:=alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
SYSFSU:=tfs tmpfs
SYSVMU:=uma_startup umm vmm
SYSKERNU:=vnp

define t-sub
SRCS+=$3
CSS+=$$(patsubst %,$(UOBJ)/$1/%.cs,$3)
RES+=$$(patsubst %,$(UOBJ)/$1/%.ress,$3)
BOCS+=$$(patsubst %,$2/%.boc,$3)
BINS+=$$(patsubst %,$2/%,$3)
$(UOBJ)/$1/%.tvc: $(USRC)/$1/%.sol
	$(SOLC) $$< -o $(UOBJ)/$1
	$(LINKER) compile --lib $(LIB) -a $(UOBJ)/$1/$$*.abi.json $(UOBJ)/$1/$$*.code -o $$@
$(UOBJ)/$1/%.cs: $(UOBJ)/$1/%.tvc
	$(LINKER) decode --tvc $$< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$$@
$(UOBJ)/$1/%.ress: $(UOBJ)/$1/%.cs
	$$(eval index!=grep -nw $$* etc/hosts.1 | cut -d ':' -f 1)
	$$(eval args!=jq -R '{index:$$(index),name:"$$*",c:.}' $$<)
	$$($I_c) update_model_at_index '$$(args)' >$$@
	rm -f $2/$$*.boc
$$(patsubst %,$2/%.boc,$3): $(ETC_HOSTS)
	$(TOC) account `grep -w $$(subst .boc,,$$(@F)) $$< | cut -f 1` -b $$@
endef
#$$(patsubst %,$2/%,$3): $(ETC_HOSTS)
#	mkdir -p $(TMP)/$$(@F)
#	(cd $(TMP)/$$(@F) && tonos-cli config --url gql.custler.net --abi $(UOBJ)/$1/$$(@F).abi.json --addr `grep -w $$(@F) $$< | cut -f 1`)
#	echo '(cd $(TMP)/$$(@F) && jq '{p_in: .p, argv: .argv}' $(CURDIR)/run/proc >$$(@F).args && $(TOC) -j run main $$(@F).args)' >$$@
#	chmod u+x $$@
QUOTE:='
NULL:=
SPACE:=$(NULL) $(NULL)
COMMA:=,
define t-gen-bin
$2/$1: $(ETC_HOSTS)
	mkdir -p $(TMP)/$2/$1
	(cd $(TMP)/$2/$1 && tonos-cli config --url gql.custler.net --abi $(CURDIR)/$(UOBJ)/$3/$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,(cd $(TMP)/$2/$1 && jq $(QUOTE){p_in: .p}$(QUOTE) $(CURDIR)/run/proc >$1.args && $(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >$(CURDIR)/run/proc_out ))
	chmod u+x $$@
endef
#	echo '(cd $(TMP)/$2/$1 && jq '{p_in: .p, argv: .argv}' $(CURDIR)/run/proc >$1.args && $(TOC) -j run main $1.args)' >$$@
#$(info $(call t-sub,bin,bin,$(BINU)))
$(eval $(call t-sub,bin,bin,$(BINU)))
$(eval $(call t-sub,sbin,sbin,$(SBINU)))
#$(eval $(call t-sub,stand,boot,$(BOOTU)))
$(eval $(call t-sub,usr.bin,usr/bin,$(USR.BINU)))
$(eval $(call t-sub,usr.sbin,usr/sbin,$(USR.SBINU)))
$(eval $(call t-sub,bin/eilish.dir,bin/eilish.dir,$(SHB)))
$(eval $(call t-sub,sys/fs,sbin,$(SYSFSU)))
$(eval $(call t-sub,sys/vm,sbin,$(SYSVMU)))
$(eval $(call t-sub,sys/kern,sbin,$(SYSKERNU)))

define t-gen-args
$2/$1: $(ETC_HOSTS)
	mkdir -p $(TMP)/$2/$1
	(cd $(TMP)/$2/$1 && tonos-cli config --url gql.custler.net --abi $(CURDIR)/$(UOBJ)/$3/$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,(cd $(TMP)/$2/$1\n$4 >$1.args\n$(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >$(CURDIR)/run/proc_out\ncd - ))
	chmod u+x $$@
endef


#$(info $(call t-gen-bin,type,bin/eilish.dir))
$(foreach b,$(SHB),$(eval $(call t-gen-bin,$b,bin/eilish.dir,bin/eilish.dir)))
$(foreach b,$(USR.BINU),$(eval $(call t-gen-bin,$b,usr/bin,usr.bin)))
#$(foreach b,$(BINU),$(eval $(call t-gen-bin,$b,bin,bin)))
#$(foreach b,$(BINU),$(info $(call t-gen-args,$b,bin,bin,jq --slurpfile fs $(CURDIR)/run/fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) $(CURDIR)/run/proc)))
$(foreach b,$(BINU),$(eval $(call t-gen-args,$b,bin,bin,jq --slurpfile fs $(CURDIR)/run/fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) $(CURDIR)/run/proc)))

#c0: $(patsubst %,bin/%.boc,cat eilish)
#	echo $(BOCS)
#	echo $^

bocs: $(BOCS)
	echo $^
cc: $(CSS)
	echo $(SRCS)
	echo $(CSS)
	echo $^
	@true
install: dirs cc ccb config hosts bocs
	echo Tonix has been installed successfully

config:
	$(TOC) config --url gql.custler.net

#$(BLD)/%.tvc: %.sol
#	$(SOLC) $< -o $(BLD)
#	$(LINKER) compile --lib $(LIB) $*.code -o $@
#%.cs: %.tvc
#	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@
#$(BLD)/%.dbg: $(BLD)/%.code
#	$(LINKER) compile --lib $(LIB) $< --debug-map $(BLD)/$*.dbg -o $@

define t-addr-boot
$1_a=$$(shell grep -w $1 etc/hosts.0 | cut -f 1)
endef

define t-call
$$(eval $1_r=$(TOC) -j run $$($1_a) --abi $(UOBJ)/$2/$1.abi.json)
$$(eval $1_dr=$(TOC) debug run $$($1_a) --abi $(UOBJ)/$2/$1.abi.json --debug-map $(UOBJ)/$2/$1.dbg)
$$(eval $1_c=$(TOC) call $$($1_a) --abi $(UOBJ)/$2/$1.abi.json)
endef

$(foreach c,$(INIT),$(eval $(call t-addr-boot,$c)))
$(foreach c,$(INIT),$(eval $(call t-call,$c,stand)))
$(BIN)/$I.boc: etc/hosts.0
	$(eval aa!=grep -w $S $< | cut -f 1)
	$(TOC) account $(aa) -b $@
#$(BIN)/%.boc: etc/hosts.1
#	$(eval aa!=grep -w $* $< | cut -f 1)
#	$(TOC) account $(aa) -b $@
ru:
	$($I_r) models {} | jq -j '.out'

#bocs: $(patsubst %,$(BIN)/%.boc,$(SRCS))
#	@true

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

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

uc0: $(UOBJ)/stand/$I.cs
	$(eval args!=jq -R '{c:.}' $<)
	$($I_c) upgrade_code '$(args)'

ss: $(RES)
	@true
# make s_add dir=usr.bin name=chfn
dir?=
name?=
s_add: $(UOBJ)/$(dir)/$(name).cs
	$(eval args!=jq -R '{index:0,name:"$(name)",c:.}' $<)
	$($I_c) update_model_at_index '$(args)'
#add_all: $(patsubst %,$(BLD)/%.as,$(SRCS))
#	echo $^
#$(BLD)/%.as: $(BLD)/%.cs
#	$(eval args!=jq -R '{index:0,name:"$*",c:.}' $<)
#	$($I_c) update_model_at_index '$(args)' >$@

etc/hosts.1:
	$($I_r) etc_hosts {} | jq -j '.out' | sed 's/ *$$//' >$@
hosts:
	rm -f etc/hosts.1
	make etc/hosts.1


tty tt: tx bocs
	./$<
#u: bocs
#u: $(BIN)/mddb.boc
#u: $(BIN)/md2.boc $(BIN)/mddb.boc $(BIN)/startup.boc $(BIN)/core.boc
#u: $(BIN)/startup.boc $(BIN)/core.boc $(patsubst %,$(BIN)/%.boc,$(KI))
#	./$@

V?=
#$(V).SILENT:

.PHONY: list cc ss hosts tt tty cmp bhf
.PRECIOUS: $(BIN)/*.boc
list:
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
