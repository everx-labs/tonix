MAKEFLAGS += --no-builtin-rules --warn-undefined-variables
include Makefile.common

STD:=std
SES:=session
DBG=debug
# Contracts
B:=BlockDevice
D:=DataVolume
R:=StatusReader
I:=SessionManager
C:=FileManager
MAN_CMD:=ManualCommands
MAN_SES:=ManualSession
MAN_STAT:=ManualStatus
MAN_AUX:=ManualUtility
T:=TestFS
P:=PrintFormatted
INIT:=
TA:=$D $R $B $I $C $(MAN_CMD) $(MAN_SES) $(MAN_STAT) $(MAN_AUX) $P
RKEYS:=$(KEY)/k1.keys
VAL0:=15
TST:=tests

VFS:=vfs
PROC:=$(VFS)/proc
pid:=2

DIRS:=bin $(STD) $(VFS) $(PROC)

PHONY += all genaddr init deploy balances compile clean brief
all: compile

install: dirs cc config

npid?=2
dirs:
	mkdir -p $(DIRS)
	echo / > $(PROC)/cwd
	$(eval pid:=$(npid))
	mkdir -p $p
	cp $p/../cwd $p/
	mkdir -p $p/fd $p/fdinfo $p/map_files
	mkdir -p $p/fd/0 $p/fd/1 $p/fd/2
config:
	$(TOC) config --url gql.custler.net --async_call=true

#clean:
#	for d in $(DIRS); do (cd "$$d" && rm -f *); done

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

cc: $(patsubst %,$(BLD)/%.tvc,$(INIT) $(TA))
	du -sb $^
caj: $(patsubst %,$(BLD)/%.abi.json,$(INIT) $(TA))
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

$(STD)/%.tvc:
	$(TOC) account -d $@ $($*_a)

p=$(PROC)/$(pid)

_trace=echo $1 $2 >$(STD)/trace

define t-addr
$$(eval $1_a!=grep -w $1 etc/hosts | cut -f 1)
$$(eval $1_r0:=$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json)
$$(eval $1_c0:=$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json)
$1_r=$$($1_r0) $$(basename $$(@F)) $$< >$$@
$1_c=$$($1_c0) $$(basename $$(@F)) $$< >$$@
$1_rd=$$($1_r0) $$(basename $$(@F)) $$< >$$@; $$(if $$(shell grep "run failed" $$@),$$(call _trace,$1,$$(basename $$(@F)))
$(STD)/$1/upgrade.args: $(BLD)/$1.stateInit
	$$(file >$$@,$$(call _args,c,$$(file <$$<)))
$(STD)/$1/%.dout: $p/%.args
	-$(TOC) -j run $$($1_a) --abi $(BLD)/$1.abi.json $$(basename $$(@F)) $$< >$$@
	$$(if $$(findstring failed,$$(file <$$@)),echo $1 $$* >$(STD)/trace; jq -c '.' <$$< >$(STD)/$$*.args)
$(DBG)/$1.%: $(STD)/$1.tvc $p/%.args
	$(LINKER) test --trace-minimal $$< -a $(BLD)/$1.abi.json -m $$* -p `jq -c '.' <$$(word 2,$$^)` >$$@
endef

#$(foreach c,$(TA),$(info $(call t-addr,$c)))
$(foreach c,$(TA),$(eval $(call t-addr,$c)))

c?=
m?=
trace: $(DBG)/$c.$m
	echo $^

$(STD)/do_trace: $(STD)/trace
	$(TOC) account -d $(STD)/$(word 1, $(file <$<)).tvc $($*_a)

trace2: $(STD)/do_trace
	echo $^

define t-call
$(STD)/$1/$2.res: $(STD)/$1/$2.args
	$(TOC) call $$($1_a) --abi $(BLD)/$1.abi.json $2 $$(word 1,$$^) >$$@
endef

$(STD)/%/boc:
	$(TOC) account $($*_a) -b $@

define t-run2
$(STD)/$1/$2.out: $(STD)/$1/boc
	$(TOC) -j run --boc $$< --abi $(BLD)/$1.abi.json $2 {} | jq -r '.$2' >$$@
endef

_d=init upgrade
$(foreach b,$(TA),$(foreach c,$(_d),$(eval $(call t-call,$b,$c))))

PRS:=$(STD)/parsed

_jq=jq '.$1' <$@ > $p/$1
_jqr=jq -r '.$1' <$@ > $p/$1
_jqq=jq $2 '$3 .$1' <$@ > $p/$1

_jqa=$(foreach f,$1,$(call _jq,$f);) $(_p); $(_e)
_jqra=$(foreach f,$1,$(call _jqr,$f);)
_p=jq -j 'select(.out != null) .out' <$@ | tee $p/fd/1/out;jq -j 'select(.err != null) .err' <$@ | tee $p/fd/2/err
#_a=jq -r 'select(.action != null) .action' <$@ >$p/action
_jqsnn=$(call _jqq,$1,,select(.$1 != null))
_e=$(call _jqsnn,errors)
_f=grep "run failed" $@ && echo $(basename $(@F)) >$p/failed

npid?=3
process:
	$(eval pid:=$(npid))
	mkdir -p $p
	cp $p/../cwd $p/
	mkdir -p $p/fd $p/fdinfo $p/map_files
	mkdir -p $p/fd/0 $p/fd/1 $p/fd/2

g?=
ru: $p/$g.out
ca: $p/$g.res

BIL:=$(STD)/billion
$(BIL):
	echo /1000000000 >$@
$p/%.args:
	$(file >$@,{})

$p/login: $(STD)/login
	cp $< $@
$p/parse.args: $p/login $p/cwd $(STD)/s_input
	jq -sR '. | split("\n") | {i_login: .[0], i_cwd: .[1], s_input: .[2]}' $^ >$@
$p/parse.out: $p/parse.args
	$($I_r)
	$(call _jqa,session input target names addresses arg_list input.command)
	$(call _jqra,cwd source action ext_action)

$p/print_error_message.args: $p/input.command $p/errors
	jq -s '{command: .[0], errors: .[1]}' $^ >$@
$p/print_error_message.out: $p/print_error_message.args
	$($P_r)
	$(call _jqa,)
$p/read.out: $p/read.args
	$($B_r)
	$(call _jqa,)
$p/update_nodes.args: $p/session $p/ios
	jq -s '{session: .[0], ios: .[1]}' $^ >$@
$p/update_nodes.res: $p/update_nodes.args
	$($B_c)

write_all: $p/session $p/source
	$(eval files:=$(file <$(word 2,$^)))
	$(foreach f,$(files),$(file >$p/fd/$f.args,{"session":$(file <$(word 1,$^))$(comma)"path":"$(notdir $f)","text":$(shell jq -Rs '.' <$f)}))
	$(foreach f,$(files),$($B_c0) write_to_file $p/fd/$f.args;)

copy_in: $p/source
	cp $(file <$<) $p/fd/0/

$(STD)/text_in: $p/source
	jq -Rs '.' $^ >$@
$p/write_to_file.args: $p/session $p/target $(STD)/text_in
	jq -s '{session: .[0], path: .[1], text: .[2]}' $^ >$@
$p/write_to_file.res: $p/write_to_file.args
	$($B_c)

$p/fstat.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/fstat.out: $p/fstat.args
	$($R_r)
	$(call _jqa,)
$p/file_op.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/file_op.out: $p/file_op.args
	$($C_r)
	$(call _jqa,ios)
	$(call _jqra,action)
$p/process_command.args: $p/session $p/input
	jq -s '{session: .[0], input: .[1]}' $^ >$@
$p/process_command.out: $p/process_command.args
	$($P_r)
	$(call _jqa,out err)
$p/format_text.args: $p/input $p/texts $p/arg_list
	jq -s '{input: .[0], texts: .[1], args: .[2]}' $^ >$@
$p/format_text.out: $p/format_text.args
	$($P_r)
	$(call _jqa,out)
$p/read_indices.args: $p/arg_list
	jq -s '{args: .[0]}' $^ >$@
$p/read_indices.out: $p/read_indices.args
	$($B_r)
	$(call _jqa,texts)

$p/process_file_list.args: $p/session $p/input $p/dd_names_j $p/dd_indices_j
	jq -s '{session: .[0], input: .[1], names: .[2], indices: .[3]}' $^ >$@
$p/process_file_list.out: $p/process_file_list.args
	$($C_r)
	$(call _jqa,ios)

$p/fd/%/write_fd.args: $p/fd/%/start $p/fd/%/blocks
	jq -s '{fd: $*, start: .[0], blocks: .[1]}' $^ >$@
$p/fd/%/write_fd.res: $p/fd/%/write_fd.args
	$($B_c)
$p/next_write.args: $p/fdinfo/%
	jq -n '{fdi: .[$*]}' >$@
$p/fd/%/next_write.out: $p/next_write.args
	$($B_r)
	$(call _jqa,start count)

$p/nw_%:
	$($B_r0) next_write '{"fdi":$*}' >$@
	jq '.start' <$@ >$p/fd/$*/start
	jq '.count' <$@ >$p/fd/$*/count
	jq -Rs '[.]' $p/fd/$*/* >$p/fd/$*/blocks

$p/_proc.out: $p/_proc.args
	$($B_r)
	$(call _jqa,_proc)
$p/fd_table: $p/_proc.out
	jq -r '._proc["2"].fd_table' <$< >$@
$p/blk_size: $(STD)/$B/_dev.out
	jq -r '.[0].blk_size' <$< >$@
	$(foreach f,$(files),split -d --number=l/`grep ' $f ' $< | cut -d ' ' -f 3` $(SRC)/$f $f.;)
$p/fd_list: $p/fd_table
	jq -r 'keys | .[]' <$< >$@

fd_%: $p/op_table $p/fd_table
	jq -rS 'to_entries[] | select(.value.name=="$*") | .key' <$(word 2,$^)
nwr_%: $p/fd_table
	$(eval fdi!=jq -rS 'to_entries[] | select(.value.name=="$*") | .key' <$(word 1,$^))
	$($B_r0) next_write '{"pid":$(pid),"fdi":$(fdi)}'

dirrs: $p/fd_list $p/fd_table
	$(eval fds:=$(strip $(file <$<)))
	$(foreach f,$(fds),mkdir -p $p/fd/$f;)
	$(foreach f,$(fds),jq '.["$f"]' <$(word 2,$^) >$p/fdinfo/$f;)
fi_%: $p/fdinfo/%
	$(eval name!=jq -r '.name' <$<)
	$(eval n_blk!=jq -r '.n_blk' <$<)
	$(eval blk_size:=$(file <$p/blk_size))
	split -b $(blk_size) -d $(name) $p/fd/$*/
	jq -s 'blocks: .[]' $p/fd/$*/* >$p/blocks

$p/op_table: $p/names
	du --apparent-size `jq -r '.[]' <$<` >$@
	cut -f 1 $@ >$p/dd_indices
	cut -f 2 $@ >$p/dd_names
	jq -R '[.]' <$p/dd_indices > $p/dd_indices_j
	jq -R '[.]' <$p/dd_names > $p/dd_names_j

%.boc: %.addr
	$(TOC) account $(file < $<) -b $@
run_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(TOC) -j run --boc $< --abi $(word 2,$^) $f {} | jq -r '.$l'
print: $(STD)/out $(STD)/err
	cat $<
	cat $(word 2,$^)
	rm -f $^

u_%: $(STD)/%/upgrade.args
	$($*_c0) upgrade $<
	rm -f $(STD)/$*/*
i_%:
	$($*_c0) init {}

define t-dump
$$(foreach r,$$(pv_$1),$$(eval $$(call t-run2,$1,$$r)))

d_$1: $$(patsubst %,$(STD)/$1/%.out,$$(pv_$1))
	echo $$^
endef

pv_Dev=_dev _proc
pv_Export=$(pv_Dev) _sb_exports
pv_Import=$(pv_Dev)
pv_$C=$(pv_Dev)
pv_$T=$(pv_Dev) _ffs
pv_$R=$(pv_Dev)
pv_$I=$(pv_Dev) _command_info
pv_$B=$(pv_Dev) _cdata _file_table _blocks _fd_table
pv_$D=$(pv_Export)
pv_$P=$(pv_Import)
pv_$(MAN_CMD)=$(pv_Export)
pv_$(MAN_SES)=$(pv_Export)
pv_$(MAN_STAT)=$(pv_Export)
pv_$(MAN_AUX)=$(pv_Export)

$(foreach c,$(TA),$(eval $(call t-dump,$c)))

_rb=$(TOC) -j run --boc $< --abi $(word 2,$^)
d3_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(foreach r,$(pv_$*),$(_rb) $r {} | jq -r '.$r' >$(STD)/$*/$r.out;)

l?=1
dfs_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(_rb) dump_fs '{"level":"$l"}' | jq -r '.value0'

dimp_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(_rb) dump_imports {} | jq -r '.out'

_print_status=echo -n $1 "\t";\
	jq -j '."data(boc)"' <$(STD)/accounts/$1.data | wc -m | tr -d '\n';\
	echo -n "\t";\
	jq -j '.balance' <$(STD)/accounts/$1.data | cat - $(BIL) | bc | tr -d '\n';\
	echo -n "\t";\
	jq -j '.last_paid' <$(STD)/accounts/$1.data | xargs -I{} date --date=@{} +"%b %d %T"
$p/hosts: $p/names
	jq -r '.[]' <$< >$@
account_data: $p/hosts
	rm -f $(STD)/accounts/*
	$(eval hosts:=$(strip $(file <$(word 1,$^))))
	$(foreach h,$(hosts),$(TOC) -j account `grep -w $h etc/hosts | cut -f 1` >$(STD)/accounts/$h.data;)
	$(foreach h,$(hosts),$(call _print_status,$h);)

#_escape2=$(shell jq -Rs '.' <$1)
#_call_block_device=$(TOC) call $($B_a) --abi $(BLD)/$B.abi.json
#$(STD)/files: $(STD)/parse.out
#	jq -r '.names[]' < $< >$@
#$(STD)/open: $(STD)/files
#	$(foreach f,$(file < $^),$(call _wtf,$f);)

#$(STD)/dirs_to_open: $(STD)/parse.out
#	jq -r '.names[]' < $< >$@
#$(STD)/files_to_open: $(STD)/dirs_to_open
#	mkdir -p $(STD)/ml/$(file <$^)
#	$(eval dirs:=$(file <$^))
#	echo DIRS $(dirs)
#	$(eval files_in_dirs:=$(wildcard $(dirs)/*))
#	echo $(files_in_dirs) >$@
#$(STD)/carr: $(STD)/dirs_to_open $(STD)/files_to_open
#	$(eval dirs:=$(file <$<))
#	$(eval files_in_dirs:=$(file <$(word 2,$^)))
#	echo DIRS $(dirs)
#	echo $(files_in_dirs)
#	$(foreach f,$(files_in_dirs),$(file >$(STD)/ml/$f.mld,$(file <$(STD)/ses.temp)$(comma)"path":"$(notdir $f)","text":$(shell jq -Rs '.' <$f)}))
#$(STD)/mount_el: $(STD)/dirs_to_open $(STD)/carr $(STD)/files_to_open
#	$(eval hop:=$(wildcard $(STD)/ml/$(file <$<)/*.mld))
#	$(foreach f,$(hop),$(_call_block_device) write_to_file $f;)

#$(STD)/request_mount: $(STD)/request_mount.args
#	$(_call_block_device) request_mount $<

tt: bin/xterm
	./$<
bin/xterm: $(SRC)/xterm.c
	gcc $< -o $@

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

#include Disk.make

PHONY += FORCE
FORCE:

.PHONY: $(PHONY)

V?=
$(V).SILENT:
