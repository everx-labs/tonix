MAKEFLAGS += --no-builtin-rules --warn-undefined-variables
include Makefile.common

STD:=std
SES:=session

# Contracts
B:=BlockDevice
D:=DataVolume
F:=Stat
I:=InputParser
C:=CommandProcessor
CM:=CommandManual
SM:=StatusManual
INIT:=
TA:=$D $F $B $I $C $(CM) $(SM)
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
$$(eval $1_a!=grep -w $1 etc/hosts | cut -f 1)
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

$(STD)/%/boc:
	$(TOC) account $($*_a) -b $@

define t-run2
$(STD)/$1/$2.out: $(STD)/$1/boc
	$(TOC) -j run --boc $$< --abi $(BLD)/$1.abi.json $2 {} | jq -r '.$2' >$$@
endef

_d=init upgrade
$(foreach b,$(TA),$(foreach c,$(_d),$(eval $(call t-call,$b,$c))))

$(STD)/read.out: $(STD)/read.args
	$(TOC) -j run $($B_a) --abi $(BLD)/$B.abi.json read $< >$@

#$(STD)/add_nodes.res: $(STD)/add_nodes.args
#	$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json add_nodes $< >$@

$(STD)/update_nodes.res: $(STD)/update_nodes.args
	$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json update_nodes $< >$@

$(STD)/ses.temp: $(STD)/parse.out
	jq 'del(.std,.action,.input,.re,.ios,.ines,.redirect,.names,.addresses)' < $< | sed '9d' > $@

$(STD)/write_to_file.args: $(STD)/parse.out $(STD)/ses.temp $(STD)/out
	$(eval file_name!=jq -r '.redirect' <$<)
	$(file >$@,$(file < $(word 2,$^))$(comma)"path":"$(file_name)","text":"$(strip $(file <$(word 3,$^)))"})

$(STD)/wtf.args: $(STD)/files
	$(foreach f,$(file < $^),$(call _write_to_file_args,$f))
$(STD)/write_to_file.res: $(STD)/write_to_file.args
	$(call _write_to_file) $< >$@
#	$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json write_to_file $< >$@

$(STD)/parse.out: $(STD)/parse.args
	$(TOC) -j run $($I_a) --abi $(BLD)/$I.abi.json parse $< >$@
$(STD)/stat.out: $(STD)/stat.args
	$(TOC) -j run $($F_a) --abi $(BLD)/$F.abi.json fstat $< >$@
$(STD)/process.out: $(STD)/process.args
	$(TOC) -j run $($C_a) --abi $(BLD)/$C.abi.json process $< >$@

$(STD)/action.1: $(STD)/parse.out
$(STD)/action.2: $(STD)/stat.out
$(STD)/action.3: $(STD)/process.out

$(STD)/action.%:
	jq -r '.action' < $< >$@
	jq -j '.std.out' < $<
	jq -j '.std.err' < $<

%.boc: %.addr
	$(TOC) account $(file < $<) -b $@
run_%: %.boc %.abi.json
	$(TOC) -j run --boc $< --abi $(word 2,$^) $f {}
print: $(STD)/out $(STD)/err
	cat $<
	cat $(word 2,$^)
	rm -f $^

u_%: $(STD)/%/upgrade.args
	$(TOC) call $($*_a) --abi $(BLD)/$*.abi.json upgrade $<
i_%:
	$(TOC) call $($*_a) --abi $(BLD)/$*.abi.json init {}

define t-dump
$$(foreach r,$$(pv_$1),$$(eval $$(call t-run2,$1,$$r)))

d_$1: $$(patsubst %,$(STD)/$1/%.out,$$(pv_$1))
	echo $$^
endef

pv_FSync:=_fs _mnt _sb_exports _dev
pv_$C=$(pv_FSync)
pv_$(F)=$(pv_FSync)
pv_$I=$(pv_FSync) _command_info
pv_$B=$(pv_FSync) _cdata _char_dev
pv_$D=$(pv_FSync)
pv_$(CM)=$(pv_FSync)
pv_$(SM)=$(pv_FSync)

$(foreach c,$(TA),$(eval $(call t-dump,$c)))

_rb=$(TOC) -j run --boc $< --abi $(word 2,$^)
d3_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(foreach r,$(pv_$*),$(_rb) $r {} | jq -r '.$r' >$(STD)/$*/$r.out;)
$(STD)/hosts: $(STD)/parse.out
	jq -r '.names[]' < $< >$@
$(STD)/addresses: $(STD)/parse.out
	jq -r '.addresses[]' < $< >$@

$(STD)/accounts/%.data: $(STD)/hosts
	$(eval hosts:=$(strip $(file <$<)))
	$(foreach h,$(hosts),$(TOC) -j account `grep -w $h etc/hosts | cut -f 1` >$(STD)/accounts/$h.data;)

$(STD)/accounts/%.summary: $(STD)/accounts/%.data
	echo $* > $@
	jq -r '.acc_type' <$< >>$@
	jq -r '.balance' <$< | xargs -I {} echo {} /1000000000 | bc >>$@
	jq -r '."data(boc)"' <$< | wc -m >>$@

_print_status=echo -n $1 "\t";\
	jq -j '."data(boc)"' <$(STD)/accounts/$1.data | wc -m | tr -d '\n';\
	echo -n "\t";\
	jq -j '.acc_type' <$(STD)/accounts/$1.data;\
	echo -n "\t";\
	jq -j '.balance' <$(STD)/accounts/$1.data | xargs -I {} echo {} /1000000000 | bc
account_data: $(STD)/hosts
	rm -f $(STD)/accounts/*
	$(eval hosts:=$(strip $(file <$(word 1,$^))))
	$(foreach h,$(hosts),$(TOC) -j account `grep -w $h etc/hosts | cut -f 1` >$(STD)/accounts/$h.data;)
$(STD)/status: $(STD)/hosts
	$(eval hosts:=$(strip $(file <$(word 1,$^))))
	$(foreach h,$(hosts),$(call _print_status,$h);)

$(STD)/balance: $(STD)/addresses $(STD)/hosts
	rm -f $@
	touch $@
	$(eval addresses:=$(strip $(file <$<)))
	$(foreach a,$(addresses),$(TOC) -j account $a | jq -r '.balance' | xargs -I {} echo {} /1000000000 | bc >>$@;)
	paste $(word 2,$^) $@ $< | column -t

$(STD)/mounts: $(STD)/addresses $(STD)/hosts
	rm -f $@
	touch $@
	$(eval addresses:=$(strip $(file <$<)))
	paste $(word 2,$^) $< | column -t

define newline

endef

_escape=$(subst $(newline),\n,$(strip $1))
#_escape2=$(subst ",\",$(strip $1))
_escape2=$(shell jq -Rs '.' <$1)
_write_to_file=$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json write_to_file
_call_block_device=$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json
#_write_to_file_args=$(file >$@,$(file <$(STD)/ses.temp)$(comma)"path":"$1","text":"$(call _escape2,$(file <$1))"})
_write_to_file_args=$(file >$@,$(file <$(STD)/ses.temp)$(comma)"path":"$(notdir $1)","text":$(call _escape2,$1)})
_wtf=$(call _write_to_file_args,$1)\
	$(_write_to_file) $@
$(STD)/files: $(STD)/parse.out
	jq -r '.names[]' < $< >$@
$(STD)/open: $(STD)/files
	$(foreach f,$(file < $^),$(call _wtf,$f);)

$(STD)/dirs_to_open: $(STD)/parse.out
	jq -r '.names[]' < $< >$@
$(STD)/files_to_open: $(STD)/dirs_to_open
	mkdir -p $(STD)/ml/$(file <$^)
	$(eval dirs:=$(file <$^))
	echo DIRS $(dirs)
	$(eval files_in_dirs:=$(wildcard $(dirs)/*))
	echo $(files_in_dirs) >$@
$(STD)/carr: $(STD)/dirs_to_open $(STD)/files_to_open
	$(eval dirs:=$(file <$<))
	$(eval files_in_dirs:=$(file <$(word 2,$^)))
	echo DIRS $(dirs)
	echo $(files_in_dirs)
	$(foreach f,$(files_in_dirs),$(file >$(STD)/ml/$f.mld,$(file <$(STD)/ses.temp)$(comma)"path":"$(notdir $f)","text":$(shell jq -Rs '.' <$f)}))
$(STD)/mount_el: $(STD)/dirs_to_open $(STD)/carr $(STD)/files_to_open
	$(eval hop:=$(wildcard $(STD)/ml/$(file <$<)/*.mld))
	$(foreach f,$(hop),$(_call_block_device) write_to_file $f;)

$(STD)/request_mount: $(STD)/request_mount.args
	$(_call_block_device) request_mount $<

tt: bin/xterm
	./$<
bin/xterm: $(SRC)/xterm.c
	gcc $< -o $@

#TEST_DIRS:=$(wildcard $(TST)/*/*.in)
TEST_DIRS:=$(wildcard $(TST)/*/*01.in)

vpath %.diff %.log %.golden %.tests $(TST)

$(TST)/%.diff: $(TST)/%.log $(TST)/%.golden
	-diff $^ >$@
	echo DIFF:
	cat $@
$(TST)/%.log: $(TST)/%.tests
	./bin/xterm <$< | tee $@
test:
	rm -f $(TST)/$t.diff $(TST)/$t.log
	make $(TST)/$t.diff

$(SYS)/%.args:
	$(file >$@,{})

#include Disk.make

PHONY += FORCE
FORCE:

.PHONY: $(PHONY)

V?=
$(V).SILENT:
