MAKEFLAGS += --no-builtin-rules --warn-undefined-variables
include Makefile.common

STD:=std
SES:=session

# Contracts
T:=Repo
B:=BlockDevice
D:=DataVolume
F:=Stat
I:=InputParser
C:=CommandProcessor
O:=Options
S:=SuperBlock
INIT:=$T
TA:=$D $F $B $I $C $O $S
#TA:=$S $T
RKEYS:=$(KEY)/k1.keys
VAL0:=15

PHONY += all genaddr init deploy balances compile clean brief
all: compile

#clean:
#	for d in $(DIRS); do (cd "$$d" && rm -f *); done

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

cc: $(patsubst %,$(BLD)/%.tvc,$(INIT) $(TA))
	du -sb $^
deploy: $(DEPLOYED)
	-cat $^
$(BLD)/%.code $(BLD)/%.abi.json: $(SRC)/%.sol
	$(SOLC) $< -o $(BLD)

$(BLD)/%.tvc: $(BLD)/%.code $(BLD)/%.abi.json
	$(LINKER) compile --lib $(LIB) $< -a $(word 2,$^) -o $@

$(BLD)/%.shift: $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS)
	$(TOC) genaddr $< $(word 2,$^) --setkey $(word 3,$^) | grep "Raw address:" | sed 's/.* //g' >$@

$(BLD)/%.cargs:
	$(file >$@,{})

$(BLD)/%.deployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL0))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@

$(BLD)/%.stateInit: $(BLD)/%.tvc
	$(BASE64) $< >$@

define t-call
$(SYS)/$1/$2.res: $(SYS)/$1/address $(BLD)/$1.abi.json $(SYS)/$1/$2.args
	$(TOC) call $$(file <$$<) --abi $$(word 2,$$^) $2 $$(word 3,$$^) >$$@
endef

define t-run
$(SYS)/$1/$2.out: $(SYS)/$1/address $(BLD)/$1.abi.json $(SYS)/$1/$2.args
	$(TOC) -j run $$(file <$$<) --abi $$(word 2,$$^) $2 $$(word 3,$$^) >$$@
endef

$(SYS)/%/upgrade.args: $(BLD)/%.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))

$(SYS)/$I/upgrade.args: $(BLD)/$I.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))
$(SYS)/$C/upgrade.args: $(BLD)/$C.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))
$(SYS)/$O/upgrade.args: $(BLD)/$O.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))
$(SYS)/$F/upgrade.args: $(BLD)/$F.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))
$(SYS)/$S/upgrade.args: $(BLD)/$S.stateInit
	$(file >$@,$(call _args,c,$(file <$<)))

_d=init upgrade
$(foreach b,$D $I $B $C $O $F $S,$(foreach c,$(_d),$(eval $(call t-call,$b,$c))))

$(STD)/read.out: $(STD)/read.args $(SYS)/$B/address $(BLD)/$B.abi.json
	$(TOC) -j run $(file < $(word 2,$^)) --abi $(word 3,$^) read $< >$@

$(STD)/write.res: $(STD)/write.args $(SYS)/$B/address $(BLD)/$B.abi.json
	$(TOC) call $(file < $(word 2,$^)) --abi $(word 3,$^) put $< >$@

$(STD)/parse.out: $(SYS)/$I/address $(BLD)/$I.abi.json $(STD)/parse.args
	$(TOC) -j run $(file < $<) --abi $(word 2,$^) parse $(word 3,$^) >$@
	jq -r '.action' < $@ >$(STD)/action
$(STD)/stat.out: $(SYS)/$F/address $(BLD)/$F.abi.json $(STD)/stat.args
	$(TOC) -j run $(file < $<) --abi $(word 2,$^) fstat $(word 3,$^) >$@
	jq -r '.action' < $@ >$(STD)/action2
$(STD)/process.out: $(SYS)/$C/address $(BLD)/$C.abi.json $(STD)/process.args
	$(TOC) -j run $(file < $<) --abi $(word 2,$^) process $(word 3,$^) >$@
	jq -r '.action' < $@ >$(STD)/action3
	jq -r '.o_ses.wd' < $@ >$(STD)/wd
	jq -r '.o_ses' < $@ >$(STD)/session

u_%: $(SYS)/%/upgrade.res
	echo $^
i_%: $(SYS)/%/init.res
	echo $^

define t-dump
$$(foreach r,$$(pv_$1),$$(eval $$(call t-run,$1,$$r)))

d_$1: $$(patsubst %,$(SYS)/$1/%.out,$$(pv_$1))
	jq -r '.' <$$<
endef
pv_FSync:=_init_ids _inodes _ugroups _users  _dc _de
pv_$C=$(pv_FSync)
pv_$F=$(pv_FSync)
pv_$S=$(pv_FSync)
pv_$I=$(pv_FSync) _command_names
pv_$B=$(pv_FSync) _dev _cdata _char_dev
pv_$D=_exports _command_names _error_text
pv_$O=_exports

$(foreach c,$C $S $I $B $F $D $O,$(eval $(call t-dump,$c)))

tt: bin/xterm
	./$<
bin/xterm: $(SRC)/xterm.c
	gcc $< -o $@

$(SYS)/%.args:
	$(file >$@,{})

#include Disk.make

PHONY += FORCE
FORCE:

.PHONY: $(PHONY)

V?=
$(V).SILENT:
