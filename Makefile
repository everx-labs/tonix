MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
UNAME_S:=$(shell uname -s)

# Tools directories
TOOLS_BIN:=~/bin
SOLC:=$(TOOLS_BIN)/solc
SOLD:=$(TOOLS_BIN)/sold
LIB:=$(TOOLS_BIN)/stdlib_sol.tvm
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

URL:=gql.custler.net
#URL:=rfld-dapp01.ds1.itgold.io/graphql
GIVER:=Novi
#_pay=$(TOOLS_BIN)/$(GIVER)/s4.sh $1 $2
_pay=$(TOOLS_BIN)/$(GIVER)/s3.sh $1 $2
#_pay=$(TOOLS_BIN)/$(GIVER)/s2.sh $1 $2

SRC:=usr/src
BLD:=build
RKEYS:=~/k1.keys
VAL0:=15

R_ROOT:=~/tonix
INC_PATH:=$(R_ROOT)/usr/src/include
LIB_PATH:=$(R_ROOT)/usr/src/lib
SYS_LIB_PATH:=$(R_ROOT)/usr/src/sys/sys

# Contracts
I:=Repo

#PRIME:=$I
#H:=host
#PRIME:=$S $I
PRIME:=$I
#H:=hive

#UTILS:=basename cat colrm column cp cut df dirname du dumpe2fs env expand file findmnt finger fsck fuser getent grep groupadd groupdel groupmod groups head hostname id last ln login look losetup ls lsblk lslogins man mkdir mke2fs mkfs mount mountpoint mv namei newgrp paste pathchk printenv ps readlink realpath rev rm rmdir stat tail tfs tmpfs touch tr umount uname unexpand useradd userdel usermod utmpdump wc whatis who whoami lsof explain reboot sdz vnp hive umm vmstat vmm mdb diff mddb md2 patch
#OPT:=dist adc jury
HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export getopts hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset esh
#DEVICES:=null
#FILES:=motd group procfs
#KI:=core zone_misc corev2 kview corev3 kview2 stg0 bringup bringup2 bringup3 kview3 bringup4 zones_viewer patch_zone zones_host stg1 stg2 stg3 file_host call_proxy stg4 stg5 stg41 stg42 patch3 file_index stg44 GSV idx4
#HOSTS:=uma_startup

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
UOBJ:=$(TMP)
MAN:=$(USH)/man
LOG:=var/log
DIRS:=$(BIN) $(TMP) $(RUN) $(USH) $(LOG)

dirs:
	mkdir -p $(DIRS)

ETC_HOSTS:=$(CURDIR)/etc/hosts.1
STORED_IMGS:=$(TMP)/stand/$I/images
BOOTU:=Repo
BINU:=cat cp df ln ls mkdir mv realpath rm rmdir eilish
SBINU:=fsck mount reboot umount
USR.BINU:=basename chfn colrm column cut diff dirname env expand fuser look lslogins lsof man paste patch pathchk printenv ps rev tail tr uname unexpand whatis whoami
USR.BINU2:=du file findmnt finger getent grep groups head hostid hostname id last login lsblk mountpoint namei newgrp readlink stat touch wc who
USR.SBINU:=groupadd groupdel groupmod useradd userdel usermod
USR.SBINU2:=dumpe2fs mke2fs mkfs
SHB:=alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset special esh
SYSFSU:=tfs tmpfs
SYSVMU:=uma_startup umm vmm
SYSKERNU:=vnp syscall
TOOLS:=tucred tfiledesc
UTILS:=$(BINU) $(USR.BINU)
SYSUTILS:=$(SBINU) $(USR.SBINU) $(SYSFSU)

define t-sub
SRCS+=$$(patsubst %,$2/%.sol,$3)
CSS+=$$(patsubst %,$1/%.cs,$3)
C0S+=$$(patsubst %,$1/%.c0,$3)
CDS+=$$(patsubst %,$1/%.cds,$3)
RES+=$$(patsubst %,$1/%.ress,$3)
BOCS+=$$(patsubst %,$1/%.boc,$3)
BINS+=$$(patsubst %,$1/%,$3)
MANP+=$$(patsubst %,$1/%.man,$3)
DBG+=$$(patsubst %,$1/%.dbg,$3)
CNF+=$$(patsubst %,$1/%.conf,$3)
$1/%.tvc: $2/%.sol
	$(SOLD) $$< -I $(INC_PATH) -I $(LIB_PATH) -I $(SYS_LIB_PATH) -O $$(@D)
$1/%.cs: $1/%.tvc
	$(LINKER) decode --tvc $$< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$$@
	rm -f $$(@D)/$$*.boc
$1/%.ress: $1/%.cs $1/%.c0
	diff $$^ || ./bin/Repo update_model_at_index `grep -nw $$* $(ETC_HOSTS) | cut -d ':' -f 1 | xargs -I{} echo {}-1 | bc`  $$< >$$@;
$$(patsubst %,$1/%.boc,$3): $(ETC_HOSTS)
	$(TOC) account `grep -w $$(subst .boc,,$$(@F)) $$< | cut -f 1` -b $$@
$(MAN)/%.0: $1/%.boc $1/%.abi.json
	$(TOC) -j run --boc $$< --abi $$(word 2,$$^) builtin_help {} >$$@
$1/%.conf: $(ETC_HOSTS) $1/%.abi.json
	$(TOC) -c $$@ config --abi $$(word 2,$$^) --addr `grep -w $$(subst .conf,,$$(@F)) $$< | cut -f 1` --url $(URL) --is_json true --method main
$1/%.c0: $(STORED_IMGS)
	jq -r '.[] | select (.name=="$$*") | .code' $$< | tr -d '\n' >$$@
$1/%.cds: $1/%.cs $1/%.c0
	-diff $$< $$(word 2,$$^)
endef
#	-diff $$< $$(word 2,$$^) && touch $$(subst .cds,.ress,$$(@F))
#	rm -f $$(@D)/$$*.boc
QUOTE:='
NULL:=
SPACE:=$(NULL) $(NULL)
COMMA:=,

#$(eval $(call t-sub,$(UOBJ)/stand,$(USRC)/stand,$(BOOTU)))
#$(info $(call t-sub,$(UOBJ)/bin/eilish.dir,$(USRC)/bin/eilish.dir,alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset))
$(eval $(call t-sub,$(UOBJ)/bin/eilish.dir,$(USRC)/bin/eilish.dir,alias builtin cd command compgen complete declare dirs echo enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset esh josh jobs fg kill))
#$(info $(call t-sub,$(UOBJ)/bin,$(USRC)/bin,$(BINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/bin,$(BINU)))
#$(info $(call t-sub,$(UOBJ)/sbin,$(USRC)/sbin,$(SBINU)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/sbin,$(SBINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/usr.bin,$(USR.BINU)))
$(eval $(call t-sub,$(UOBJ)/bin,$(USRC)/usr.bin,$(USR.BINU2)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/usr.sbin,$(USR.SBINU)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/usr.sbin,$(USR.SBINU2)))
#$(eval $(call t-sub,bin/eilish.dir,bin/eilish.dir,$(SHB)))
$(eval $(call t-sub,$(UOBJ)/sys/fs,$(USRC)/sys/fs,$(SYSFSU)))
##$(eval $(call t-sub,sys/vm,sys/vm,$(SYSVMU)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/sys/kern,$(SYSKERNU)))
$(eval $(call t-sub,$(UOBJ)/sbin,$(USRC)/tools,$(TOOLS)))

b0: $(patsubst %,$(MAN)/%.0,$(HELP_TOPICS))
	rm -f $(MAN)/0.man
	jq 'add' $^ >$(MAN)/0.man
b1: $(patsubst %,$(MAN)/%.1,$(UTILS))
	rm -f $(MAN)/1.man
	jq 'add?' $^ >$(MAN)/1.man
b8: $(patsubst %,$(MAN)/%.8,$(SYSUTILS))
	rm -f $(MAN)/8.man
	jq 'add?' $^ >$(MAN)/8.man

bocs: $(BOCS)
	@true
conf: $(CNF)
	@true
dbg: $(CSS)
	@true
cc: $(CSS)
	@true
c0c: $(C0S)
	@true
cdc: $(CDS)
	@true
install: dirs cc config hosts bocs
	echo Tonix has been installed successfully

config:
	$(TOC) config --url $(URL)


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
ru:
	./bin/Repo models

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
# for i in df ln ls mkdir mv realpath rm rmdir eilish; do make add dir=bin name=$i; done
dir?=
name?=
add: $(UOBJ)/$(dir)/$(name).cs
	./bin/Repo add_model $(name) $<

$(STORED_IMGS):
	./bin/Repo images >$@
images: $(STORED_IMGS)
	@true
$(ETC_HOSTS): etc/hosts.0
	head -n 1 $< >$@
#	./bin/Repo etc_hosts | sed 's/ *$$//' | head -n -1 >>$@
	./bin/Repo etc_hosts | sed 's/ *$$//' >>$@
hosts:
	rm -f $(ETC_HOSTS)
	$(MAKE) $(ETC_HOSTS)

#CONFD=$(patsubst %,$(BLD)/%.cfg,$(INIT))

#$(BLD)/%.conf: $()
#	$(TOC) -c $@ config --abi ~/tonix/tmp/bin/eilish.dir/pwd.abi.json --addr `grep -w pwd etc/hosts.1 | cut -f 1` --url gql.custler.net --is_json true --method main
tty tt: tx bocs
	./$<
#EBOCS:=$(patsubst %,$(SHB)
#ei:

$(UOBJ)/eilish.dir/help/main.arg: /home/boris/tonix/usr/share/man/0.man
	jq -s '{help_files: .}' $< >$@

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
