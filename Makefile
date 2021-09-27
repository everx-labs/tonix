MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
include Makefile.common

# Contracts
A:=AccessManager
B:=BlockDevice
D:=DataVolume
R:=StatusReader
I:=SessionManager
C:=FileManager
P:=PrintFormatted
M:=ManualPages
DM:=DeviceManager
STB:=StaticBackup
PG_CMD:=PagesCommands
PG_SES:=PagesSession
PG_STAT:=PagesStatus
PG_AUX:=PagesUtility
PG_UA:=PagesAdmin
INIT:=
TA:=$A $D $R $B $I $C $M $P $(DM) $(PG_STAT) $(PG_CMD) $(PG_SES) $(PG_AUX) $(PG_UA) $(STB)
RKEYS:=$(KEY)/k1.keys
VAL0:=15
TST:=tests
VFS:=vfs
PROC:=$(VFS)/proc
STD:=std
DBG:=debug
ACC:=$(STD)/accounts

pid:=2

DIRS:=bin $(STD) $(VFS) $(PROC) $(ACC) $(DBG) $(patsubst %,$(STD)/%,$(TA))
BIL:=$(STD)/billion

PHONY += all install tools dirs cc caj trace tty tt genaddr init deploy balances compile clean
all: cc

install: dirs cc $(BIL)
	echo Tonix has been installed successfully
	$(TOC) config --url gql.custler.net --async_call=true

TOOLS_MAJOR_VERSION:=0.50
TOOLS_MINOR_VERSION:=0
TOOLS_VERSION:=$(TOOLS_MAJOR_VERSION).$(TOOLS_MINOR_VERSION)
TOOLS_ARCHIVE:=tools_$(TOOLS_MAJOR_VERSION)_$(UNAME_S).tar.gz
TOOLS_URL:=https\://github.com/tonlabs/TON-Solidity-Compiler/releases/download/$(TOOLS_VERSION)/$(TOOLS_ARCHIVE)
TOOLS_BIN:=$(LIB) $(SOLC) $(LINKER) $(TOC)
$(TOOLS_BIN):
	mkdir -p $(BIN)
	rm -f $(TOOLS_ARCHIVE)
	wget $(TOOLS_URL)
	tar -xzf $(TOOLS_ARCHIVE) -C $(BIN)

tools: $(TOOLS_BIN)
	$(foreach t,$(wordlist 2,4,$^),$t --version;)

npid?=2
dirs:
	mkdir -p $(DIRS)
	echo / > $(PROC)/cwd
	$(eval pid:=$(npid))
	mkdir -p $p
	cp $p/../cwd $p/
	mkdir -p $p/fd $p/fdinfo $p/map_files
	mkdir -p $p/fd/0 $p/fd/1 $p/fd/2

#clean:
#	for d in $(DIRS); do (cd "$$d" && rm -f *); done

DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))

cc: $(patsubst %,$(BLD)/%.tvc,$(INIT) $(TA))
	$(du) $^
caj: $(patsubst %,$(BLD)/%.abi.json,$(INIT) $(TA))
	$(du) $^
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
$1_a=$$(shell grep -w $1 etc/hosts | cut -f 1)
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

_jq=jq '.$1' <$@ >$p/$1
_jqr=jq -r '.$1' <$@ >$p/$1
_jqq=jq $2 '$3 .$1' <$@ >$p/$1

_jqa=$(foreach f,$1,$(call _jq,$f);) $(_p); $(_e)
#_jqa=$(foreach f,$1,$(call _jq,$f);) $(_p)
_jqra=$(foreach f,$1,$(call _jqr,$f);)
#_p=jq -j 'select(.out != null) .out' <$@ | tee $p/fd/1/out;jq -j 'select(.err != null) .err' <$@ | tee $p/fd/2/err
#_p=jq -j 'select(.out != null) .out' <$@ | tee $p/fd/1/out
_p=jq -j 'select(.out != null) .out' <$@
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
	$(call _jqa,session input arg_list input.command)
	$(call _jqra,cwd action ext_action)

$p/source: $p/parse.out
	jq -r '.source' <$^ >$@
$p/target: $p/parse.out
	jq '.target' <$^ >$@

$p/print_error_message.args: $p/input.command $p/errors
	jq -s '{command: .[0], errors: .[1]}' $^ >$@
$p/print_error_message.out: $p/print_error_message.args
	$($P_r)
	jq -j '.err' <$@
$p/read.out: $p/read.args
	$($B_r)
	$(call _jqa,)
$p/update_nodes.args: $p/session $p/ios
	jq -s '{session: .[0], ios: .[1]}' $^ >$@
$p/update_nodes.res: $p/update_nodes.args
	$($B_c)
$p/update_users.args: $p/session $p/ue
	jq -s '{session: .[0], ues: [.[1]]}' $^ >$@
$p/update_users.res: $p/update_users.args
	$($A_c)
$p/update_logins.args: $p/session $p/le
	jq -s '{session: .[0], le: .[1]}' $^ >$@
$p/update_logins.res: $p/update_logins.args
	$($A_c)

$p/dev_admin.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/dev_admin.res: $p/dev_admin.args
	$($(DM)_c)

write_all: $p/session $p/source
	$(eval files:=$(file <$(word 2,$^)))
	$(foreach f,$(files),$(file >$p/fd/$f.args,{"session":$(file <$(word 1,$^))$(comma)"path":"$(notdir $f)","text":$(shell jq -Rs '.' <$f)}))
	$(foreach f,$(files),$($B_c0) write_to_file $p/fd/$f.args;)

copy_in: $p/source
	cp $(file <$<) $p/fd/0/

$p/write_to_file.args: $p/session $p/target $p/text_in
	jq -s '{session: .[0], path: .[1], text: .[2]}' $^ >$@
$p/write_to_file.res: $p/write_to_file.args
	$($B_c)

$p/fstat.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/fstat.out: $p/fstat.args
	$($R_r)
	jq -j '.out' <$@

$p/dev_stat.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/dev_stat.out: $p/dev_stat.args
	$($(DM)_r)
	$(call _jqa,)

$p/account_info.args: $p/input
	jq -s '{input: .[0]}' $^ >$@
$p/account_info.out: $p/account_info.args
	$($(DM)_r)
	$(call _jqa,host_names addresses)

$p/file_op.args: $p/session $p/input $p/arg_list
	jq -s '{session: .[0], input: .[1], arg_list: .[2]}' $^ >$@
$p/file_op.out: $p/file_op.args
	$($C_r)
	$(call _jqa,ios)
	$(call _jqra,action)
$p/user_admin_op.args: $p/session $p/input
	jq -s '{session: .[0], input: .[1]}' $^ >$@
$p/user_admin_op.out: $p/user_admin_op.args
	$($A_r)
	$(call _jqa,ue)
	$(call _jqra,action)
$p/user_stats_op.args: $p/session $p/input
	jq -s '{session: .[0], input: .[1]}' $^ >$@
$p/user_stats_op.out: $p/user_stats_op.args
	$($A_r)
	$(call _jqra,action)
	jq -j '.out' <$@
$p/user_access_op.args: $p/session $p/input
	jq -s '{session: .[0], input: .[1]}' $^ >$@
$p/user_access_op.out: $p/user_access_op.args
	$($A_r)
	$(call _jqa,le)
	$(call _jqra,action)
	jq -j '.out' <$@
$p/process_command.args: $p/input
	jq -s '{input: .[0]}' $^ >$@
$p/process_command.out: $p/process_command.args
	$($P_r)
	jq -j '.out' <$@
$p/read_page.args: $p/input
	jq -s '{input: .[0]}' $^ >$@
$p/read_page.out: $p/read_page.args
	$($M_r)
	jq -j '.out' <$@
$p/format_text.args: $p/input $p/texts $p/arg_list
	jq -s '{input: .[0], texts: .[1], args: .[2]}' $^ >$@
$p/format_text.out: $p/format_text.args
	$($P_r)
	jq -j '.out' <$@
$p/read_indices.args: $p/arg_list
	jq -s '{args: .[0]}' $^ >$@
$p/read_indices.out: $p/read_indices.args
	$($B_r)
	jq '.texts' <$@ >$p/texts

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

pv_Dev=_proc _users
pv_Export=_sb_exports
pv_Import=$(pv_Dev)
pv_$A=$(pv_Export) _users _groups _group_members _user_groups _login_defs_bool _login_defs_uint16 _login_defs_string _env_bool _env_uint16 _env_string _utmp _wtmp _ttys
pv_$C=$(pv_Dev)
pv_$R=$(pv_Dev)
pv_$I=$(pv_Dev) _command_info _command_names
pv_$B=$(pv_Dev) _file_table _blocks _fd_table _dev
pv_$D=$(pv_Export)
pv_$P=$(pv_Import)
pv_$M=_command_info _command_names
pv_$(STB)=_command_info _command_names
pv_$(PG_CMD)=
pv_$(PG_SES)=
pv_$(PG_STAT)=
pv_$(PG_AUX)=
pv_$(PG_UA)=
pv_$(DM)=$(pv_Export) _devices _boot_mounts _static_mounts _current_mounts

$(foreach c,$(TA),$(eval $(call t-dump,$c)))

_rb=$(TOC) -j run --boc $< --abi $(word 2,$^)
d3_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(foreach r,$(pv_$*),$(_rb) $r {} | jq -r '.$r' >$(STD)/$*/$r.out;)

l?=1
dfs_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(_rb) dump_fs '{"level":"$l"}' | jq -r '.value0'
defs_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(_rb) dump_export_fs '{"level":"$l"}' | jq -r '.value0'

dimp_%: $(STD)/%/boc $(BLD)/%.abi.json
	$(_rb) dump_imports {} | jq -r '.out'

_print_status=printf "%s\t" $1;\
	jq -j '."data(boc)"' <$(ACC)/$1.data | wc -m | tr '\n' '\t';\
	jq -j '.balance' <$(ACC)/$1.data | cat - $(BIL) | bc | tr '\n' '\t';\
	jq -j '.last_paid' <$(ACC)/$1.data | $(date)
$p/hosts: $p/host_names
	jq -r '.[]' <$< >$@
account_data: $p/hosts
	rm -f $(ACC)/*
	$(eval hosts:=$(strip $(file <$(word 1,$^))))
	$(foreach h,$(hosts),$(TOC) -j account $($h_a) >$(ACC)/$h.data;)
	printf "Account\t\tSize\tBalance\tLast modified\n"
	$(foreach h,$(hosts),$(call _print_status,$h);)

tty tt: bin/xterm
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
