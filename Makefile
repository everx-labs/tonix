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
R:=FileReader
INIT:=$T
TA:=$D $F $B $I $C $O $S $R
#TA:=$S $T
RKEYS:=$(KEY)/k1.keys
VAL0:=15
TST:=tests
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

define t-addr
$$(eval $1_a!=grep $1 etc/hosts | cut -f 1)
$(STD)/$1/upgrade.args: $(BLD)/$1.stateInit
	$$(file >$$@,$$(call _args,c,$$(file <$$<)))
endef

$(foreach c,$(TA),$(eval $(call t-addr,$c)))

define t-call
$(STD)/$1/$2.res: $(STD)/$1/$2.args
	$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json $2 $$(word 1,$$^) >$$@
endef

define t-run
$(STD)/$1/$2.out:
	$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json $2 {} >$$@
endef

_d=init upgrade
$(foreach b,$(TA),$(foreach c,$(_d),$(eval $(call t-call,$b,$c))))

$(STD)/read.out: $(STD)/read.args
	$(TOC) -j run $($B_a) --abi $(BLD)/$B.abi.json read $< >$@

$(STD)/write.res: $(STD)/write.args
	$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json put $< >$@

$(STD)/ses.temp: $(STD)/parse.out
	jq 'del(.std,.action,.input,.re,.ios,.ines)' < $< | sed '7d' > $@

$(STD)/write_to_file.args: $(STD)/parse.out $(STD)/ses.temp $(STD)/out
	$(eval file_name!=jq -r '.input.target' <$<)
	$(file >$@,$(file < $(word 2,$^))$(comma)"path":"$(file_name)","text":"$(strip $(file <$(word 3,$^)))"})

$(STD)/write_to_file.res: $(STD)/write_to_file.args
	$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json write_to_file $< >$@

$(STD)/parse.out: $(STD)/parse.args
	$(TOC) -j run $($I_a) --abi $(BLD)/$I.abi.json parse $< >$@
$(STD)/action: $(STD)/parse.out
	jq -r '.action' < $< >$@
$(STD)/out: $(STD)/parse.out
	jq -r '.std.out' < $< >$@
$(STD)/err: $(STD)/parse.out
	jq -r '.std.err' < $< >$@
$(STD)/stat.out: $(STD)/stat.args
	$(TOC) -j run $($F_a) --abi $(BLD)/$F.abi.json fstat $< >$@
	jq -r '.action' < $@ >$(STD)/action2
$(STD)/process.out: $(STD)/process.args
	$(TOC) -j run $($C_a) --abi $(BLD)/$C.abi.json process $< >$@
	jq -r '.action' < $@ >$(STD)/action3

u_%: $(STD)/%/upgrade.args
	$(TOC) call $($*_a) --abi $(BLD)/$*.abi.json upgrade $<
i_%:
	$(TOC) call $($*_a) --abi $(BLD)/$*.abi.json init {}

define t-dump
$$(foreach r,$$(pv_$1),$$(eval $$(call t-run,$1,$$r)))

d_$1: $$(patsubst %,$(STD)/$1/%.out,$$(pv_$1))
	jq -r '.' <$$<
endef
pv_FSync:=_inodes _ugroups _users  _dc
pv_$C=$(pv_FSync)
pv_$F=$(pv_FSync)
pv_$S=$(pv_FSync)
pv_$R=$(pv_FSync)
pv_$I=$(pv_FSync) _command_names
pv_$B=$(pv_FSync) _dev _cdata _char_dev
pv_$D=_exports _command_names _error_text
pv_$O=_exports

$(foreach c,$(TA),$(eval $(call t-dump,$c)))

$(STD)/status: $(STD)/process.args $(STD)/process.out
	$(eval status!=$(TOC) account `jq -r '.std.out' < $(word 2,$^)` | grep acc_type)
	$(eval host!=jq -r '.input.args[]' < $(word 1,$^))
	$(file >$@,$(host) $(if $(findstring Active,$(status)),is alive,))

$(STD)/balance: $(STD)/process.out
	$(TOC) account `jq -r '.std.out' < $<` | grep balance | cut -d ' ' -f 8 > $@

tt: bin/xterm
	./$<
bin/xterm: $(SRC)/xterm.c
	gcc $< -o $@

#TEST_DIRS:=$(wildcard $(TST)/*/*.in)
TEST_DIRS:=$(wildcard $(TST)/*/*01.in)
test: $(TEST_DIRS)
	./bin/xterm <$^

test0:
	./bin/xterm <$(TST)/basename.tests >$(TST)/basename.log
	diff $(TST)/basename.log $(TST)/basename.golden

test1:
	./bin/xterm <$(TST)/dirname.tests >$(TST)/dirname.log
	diff $(TST)/basename.log $(TST)/basename.golden

$(SYS)/%.args:
	$(file >$@,{})

#include Disk.make

PHONY += FORCE
FORCE:

.PHONY: $(PHONY)

V?=
$(V).SILENT:
