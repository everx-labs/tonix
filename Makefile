MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
UNAME_S:=$(shell uname -s)

# Tools directories
TOOLS_BIN:=~/bin
SOLC:=$(TOOLS_BIN)/solc
LIB:=$(TOOLS_BIN)/stdlib_sol.tvm
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

#URL:=gql.custler.net
URL:=rfld-dapp01.ds1.itgold.io/graphql
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
HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export getopts hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
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
TMP:=$(CURDIR)/tmp
RUN:=run
USR:=usr
USH:=$(USR)/share
USRC:=$(USR)/src
#UOBJ:=$(USR)/obj
UOBJ:=$(TMP)
MAN:=$(USH)/man
LOG:=var/log
DIRS:=$(BIN) $(TMP) $(RUN) $(USH) $(LOG)

dirs:
	mkdir -p $(DIRS)

ETC_HOSTS:=$(CURDIR)/etc/hosts.1
BOOTU:=Repo
BINU:=cat cp df ln ls mkdir mv realpath rm rmdir eilish
SBINU:=fsck mount reboot umount
#USR.BINU:=basename chfn colrm column cut diff dirname du env expand file findmnt finger fuser getent grep groups head hostid hostname id last login look lsblk lslogins lsof man mountpoint namei newgrp paste patch pathchk printenv ps readlink rev stat tail touch tr uname unexpand wc whatis who whoami
USR.BINU:=basename chfn colrm column cut diff dirname env expand fuser look lslogins lsof man paste patch pathchk printenv ps rev tail tr uname unexpand whatis whoami
USR.BINU2:=du file findmnt finger getent grep groups head hostid hostname id last login lsblk mountpoint namei newgrp readlink stat touch wc who
#USR.SBINU:=dumpe2fs groupadd groupdel groupmod mke2fs mkfs useradd userdel usermod
USR.SBINU:=groupadd groupdel groupmod useradd userdel usermod
SHB:=alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset
SYSFSU:=tfs tmpfs
SYSVMU:=uma_startup umm vmm
SYSKERNU:=vnp
UTILS:=$(BINU) $(USR.BINU)
#$(USR.BINU2)
# $(USR.SBINU)
# $(SBINU)
define t-sub
SRCS+=$$(patsubst %,$2/%.sol,$3)
CSS+=$$(patsubst %,$1/%.cs,$3)
RES+=$$(patsubst %,$1/%.ress,$3)
BOCS+=$$(patsubst %,$1/%.boc,$3)
BINS+=$$(patsubst %,$1/%,$3)
MANP+=$$(patsubst %,$1/%.man,$3)
DBG+=$$(patsubst %,$1/%.dbg,$3)
$1/%.tvc: $2/%.sol
	$(SOLC) $$< -o $$(@D)
	$(LINKER) compile --lib $(LIB) -a $$(@D)/$$*.abi.json $$(@D)/$$*.code --debug-map $$(@D)/$$*.dbg -o $$@
$1/%.cs: $1/%.tvc
	$(LINKER) decode --tvc $$< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$$@
$1/%.ress: $1/%.cs
	./bin/Repo update_model_at_index `grep -nw $$* $(ETC_HOSTS) | cut -d ':' -f 1` $$< >$$@
	rm -f $$(@D)/$$*.boc
$$(patsubst %,$1/%.boc,$3): $(ETC_HOSTS)
	$(TOC) account `grep -w $$(subst .boc,,$$(@F)) $$< | cut -f 1` -b $$@
$(MAN)/%.0: $1/%.boc $1/%.abi.json
	$(TOC) -j run --boc $$< --abi $$(word 2,$$^) builtin_help {} >$$@
endef
#$1/%.dbg: $1/%.code
#	$(LINKER) compile --lib $(LIB) $< --debug-map $(BLD)/$*.dbg -o $@

# 	$$(eval index!=grep -nw $$* etc/hosts.1 | cut -d ':' -f 1)
#	$$(eval args!=jq -R '{index:$$(index),name:"$$*",c:.}' $$<)
#	$$($I_c) update_model_at_index '$$(args)' >$$@

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
	(cd $(TMP)/$2/$1 && tonos-cli config --url $(URL) --abi ../$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,cd $(TMP)/$2/$1)
	$$(file >>$$@,jq --slurpfile fs ../fs $(QUOTE)$$$$fs[] + {p_in: .p, argv: .argv}$(QUOTE) ../proc >$1.args)
	$$(file >>$$@,$(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >../proc_out)
	$$(file >>$$@,cd -)
	chmod u+x $$@
endef

#	$$(file >>$$@,jq --slurpfile fs ../fs $(QUOTE)$$$$fs[] + {p_in: .p, argv: .argv}$(QUOTE) ../proc >$1.args)
#	$$(file >>$$@,jq $(QUOTE){p_in: .p}$(QUOTE) ../../proc >$1.args)
#	echo '(cd $(TMP)/$2/$1 && jq '{p_in: .p, argv: .argv}' $(CURDIR)/run/proc >$1.args && $(TOC) -j run main $1.args)' >$$@
#$(info $(call t-sub,bin,bin,$(BINU)))
$(eval $(call t-sub,$(UOBJ)/stand,$(USRC)/stand,$(BOOTU)))
$(eval $(call t-sub,$(UOBJ)/bin/eilish.dir,$(USRC)/bin/eilish.dir,alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset))
#OD:=$$(UOBJ)/$1)
#$$(eval SD:=$$(USRC)/$2)
#$(info $(call t-sub,$(UOBJ)/bin,$(USRC)/bin,$(BINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/bin,$(BINU)))
#$(info $(call t-sub,$(UOBJ)/sbin,$(USRC)/sbin,$(SBINU)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/sbin,$(SBINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/usr.bin,$(USR.BINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/usr.bin,$(USR.BINU2)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/usr.sbin,$(USR.SBINU)))
#$(eval $(call t-sub,bin/eilish.dir,bin/eilish.dir,$(SHB)))
#$(eval $(call t-sub,sys/fs,sys/fs,$(SYSFSU)))
##$(eval $(call t-sub,sys/vm,sys/vm,$(SYSVMU)))
#$(eval $(call t-sub,sys/kern,sys/kern,$(SYSKERNU)))

define t-gen-args
$2/$1: $(ETC_HOSTS)
	mkdir -p $(TMP)/$2/$1
	(cd $(TMP)/$2/$1 && tonos-cli config --url gql.custler.net --abi $(CURDIR)/$(UOBJ)/$3/$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,(cd $(TMP)/$2/$1 $4 >$1.args && $(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >$(CURDIR)/run/proc_out))
	chmod u+x $$@
endef

b0: $(patsubst %,$(MAN)/%.0,$(HELP_TOPICS))
	rm -f $(MAN)/0.man
	jq 'add' $^ >$(MAN)/0.man
b1: $(patsubst %,$(MAN)/%.1,$(UTILS))
	rm -f $(MAN)/1.man
	jq 'add?' $^ >$(MAN)/1.man

#$(MAN)/%.0: $(BIN)/%.boc $(BLD)/%.abi.json
#$(MAN)/%.0: $(UOBJ)/%.boc $(BLD)/%.abi.json
#	$(TOC) -j run --boc $< --abi $(word 2,$^) builtin_help {} >$@

STMP:=$(UOBJ)/bin/eilish.dir
define t-gen-builtin
bin/eilish.dir/$1: $(ETC_HOSTS)
	mkdir -p $(STMP)/$1
	(cd $(STMP)/$1 && tonos-cli config --url $(URL) --abi ../$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,cd $(STMP)/$1)
	$$(file >>$$@,jq $(QUOTE){sv_in: .}$(QUOTE) ../vm >$1.args)
	$$(file >>$$@,$(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >../vm_out)
	$$(file >>$$@,cd -)
	chmod u+x $$@
endef

UTMP:=$(UOBJ)/bin
define t-gen-usr-bin
usr/bin/$1: $(ETC_HOSTS)
	mkdir -p $(UTMP)/$1
	(cd $(UTMP)/$1 && tonos-cli config --url $(URL) --abi ../$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,cd $(UTMP)/$1)
	$$(if $2,$$(file >>$$@,jq --slurpfile fs ../fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) ../proc >$1.args),$$(file >>$$@,jq $(QUOTE){p_in: .p}$(QUOTE) ../proc >$1.args))
	$$(file >>$$@,$(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >../proc_out)
	$$(file >>$$@,cd -)
	chmod u+x $$@
endef

USTMP:=$(UOBJ)/sbin
define t-gen-usr-sbin
usr/sbin/$1: $(ETC_HOSTS)
	mkdir -p $(USTMP)/$1
	(cd $(USTMP)/$1 && tonos-cli config --url $(URL) --abi ../$1.abi.json --addr `grep -w $1 $$< | cut -f 1`)
	$$(file >$$@,cd $(USTMP)/$1)
	$$(if $2,$$(file >>$$@,jq --slurpfile fs ../fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) ../proc >$1.args),$$(file >>$$@,jq $(QUOTE){p_in: .p}$(QUOTE) ../proc >$1.args))
	$$(file >>$$@,$(TOC) -j run `jq -r $(QUOTE).config.addr$(QUOTE) tonos-cli.conf.json` main $1.args >../proc_out)
	$$(file >>$$@,cd -)
	chmod u+x $$@
endef

#$(info $(call t-gen-bin,type,bin/eilish.dir))
#$(foreach b,$(SHB),$(eval $(call t-gen-bin,$b,bin/eilish.dir,bin/eilish.dir)))
#$(foreach b,$(USR.BINU),$(eval $(call t-gen-bin,$b,usr/bin,usr.bin)))
$(foreach b,$(BINU),$(eval $(call t-gen-bin,$b,bin,bin)))
$(foreach b,$(SBINU),$(eval $(call t-gen-bin,$b,sbin,sbin)))
$(foreach b,$(SHB),$(eval $(call t-gen-builtin,$b)))
#$(foreach b,$(USR.BINU),$(info $(call t-gen-usr-bin,$b,,)))
$(foreach b,$(USR.BINU),$(eval $(call t-gen-usr-bin,$b,,)))
$(foreach b,$(USR.BINU2),$(eval $(call t-gen-usr-bin,$b,1,)))
$(foreach b,$(USR.SBINU),$(eval $(call t-gen-usr-sbin,$b,1,)))
#$(foreach b,$(BINU),$(info $(call t-gen-args,$b,bin,bin,jq --slurpfile fs $(CURDIR)/run/fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) $(CURDIR)/run/proc)))
#$(foreach b,$(BINU),$(eval $(call t-gen-args,$b,bin,bin,jq --slurpfile fs $(CURDIR)/run/fs $(QUOTE)$$$$fs[] + {p_in: .p$(COMMA) argv: .argv}$(QUOTE) $(CURDIR)/run/proc)))
#$(foreach b,$(SHB),$(eval $(call t-gen-args,$b,bin/eilish.dir,bin/eilish.dir,jq $(QUOTE){sv_in: .}$(QUOTE) $(CURDIR)/run/vm)))
#jq --slurpfile fs $(CURDIR)/run/fs $(QUOTE)$$$$fs[] + {p_in: .p argv: .argv}$(QUOTE) $(CURDIR)/run/proc)))

#c0: $(patsubst %,bin/%.boc,cat eilish)
#	echo $(BOCS)
#	echo $^

bocs: $(BOCS)
#	echo $^
	@true
cr: $I.tvc

dbg: $(CSS)
	@true
cc: $(CSS)
#	echo $(SRCS)
#	echo $(CSS)
#	echo $^
	@true
install: dirs cc ccb config hosts bocs
	echo Tonix has been installed successfully

config:
	$(TOC) config --url $(URL)

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
#	$($I_r) models {} | jq -j '.out'
	./bin/Repo models

#bocs: $(patsubst %,$(BIN)/%.boc,$(SRCS))
#	@true

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

deploy: $(DEPLOYED)
	-cat $^

$(UOBJ)/stand/%.shift: $(UOBJ)/stand/%.tvc $(UOBJ)/stand/%.abi.json $(RKEYS)
	$(TOC) genaddr $< --abi $(word 2,$^) --setkey $(word 3,$^) | grep "Raw address:" | sed 's/.* //g' >$@
$(BLD)/%.cargs:
	$(file >$@,{})
$(BLD)/%.deployed: $(UOBJ)/stand/%.shift $(UOBJ)/stand/%.tvc $(UOBJ)/stand/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL0))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@

repo: $(DEPLOYED)
	$(foreach c,$^,printf "%s %s\n" $c `grep "deployed at address" $^ | cut -d ' ' -f 5`;)

uc0: $(UOBJ)/stand/$I.cs
	$(eval args!=jq -R '{c:.}' $<)
	$($I_c) upgrade_code '$(args)'

ss: $(RES)
	@true
# make add dir=usr.bin name=chfn
dir?=
name?=
add: $(UOBJ)/$(dir)/$(name).cs
#	$(eval args!=jq -R '{index:0,name:"$(name)",c:.}' $<)
#	$($I_c) update_model_at_index '$(args)'
	./bin/Repo add_model $(name) $<
#add_all: $(patsubst %,$(BLD)/%.as,$(SRCS))
#	echo $^
#$(BLD)/%.as: $(BLD)/%.cs
#	$(eval args!=jq -R '{index:0,name:"$*",c:.}' $<)
#	$($I_c) update_model_at_index '$(args)' >$@

etc/hosts.1:
#	$($I_r) etc_hosts {} | jq -j '.out' | sed 's/ *$$//' >$@
	./bin/Repo etc_hosts | sed 's/ *$$//' | head -n -1 >$@
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
f=login_x
m=main
d:
	$(SOLC) $f.sol
	$(LINKER) compile --lib $(LIB) $f.code -o $f.tvc
	$(LINKER) test $f --gas-limit 1000000 --abi-json $f.abi.json --abi-method constructor --abi-params {}
	$(LINKER) test $f --decode-c6 --gas-limit 100000000 --abi-json $f.abi.json --abi-method main --abi-params {}

V?=
#$(V).SILENT:

.PHONY: list cc ss hosts tt tty cmp bhf
.PRECIOUS: $(BIN)/*.boc
list:
	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
