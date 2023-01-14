MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
temps:=cmdline run_make_cmd run_execute_cmd run_dispose_cmd
OPT:=/home/boris/tonix/opt
SHETC:=$(OPT)/shell/etc
clean:
	rm -f $(temps)
in?=
cmd?=
f:=main

execute_cmd_a:=scmd
dispose_cmd_a:=scmd
help_a:=0.man
core_a:=fs
nl_a:=pgroup
%.args: env_arg %_a
	jq -s 'add' $^ >$@
define t-args
$1.args: env_arg $2
	jq -s 'add' $$^ >$$@
endef

#$(eval $(call t-args,execute_cmd,scmd))
$(eval $(call t-args,run_builtin_job,job_list))
#$(eval $(call t-args,dispose_cmd,scmd))
$(eval $(call t-args,help,0.man))
$(eval $(call t-args,core,fs))
#$(eval $(call t-args,nl,pgroup))
$(eval $(call t-args,subr,proc.1))
$(eval $(call t-args,pgroup,pgroup))

#env_arg: env cmd
env_arg: env cmd scmd
	jq -s 'add' $^ >$@

make_cmd.args: env_arg optstring
	jq -s 'add' $^ | jq --arg v1 "$(in)" '. + {input:$$v1}' >$@
execute_cmd.args: env_arg
	cp $< $@
builtin.args: env_arg
	cp $< $@

dispose_cmd.args: env_arg
	cp $< $@

define t-call
	tonos-cli -c $(word 2,$^) runx -m $f $< | tee $@ | jq '{e_in:.e} // empty' >env
endef

run_%: %.args $(SHETC)/%.conf
	$(t-call)
	jq '{cc_in:.cc} // empty' $@ >cmd
	$(post_$*)

exec_%: %.args $(SHETC)/$(cmd).conf
	$(t-call)

post_make_cmd=jq '{cmd_in:.cmd}' $@ >scmd && jq -rj '.cc_in.exec_line' cmd >cmdline
post_execute_cmd=jq '{cmd_in:.cmd}' $@ >scmd
post_builtin_job=jq '{j_in:.j}' $@ >job_list
post_dispose_cmd=jq -rj '.stdout' $@ >stdout && jq -rj '.stderr' $@ >stderr
post_builtin=

debug.%: $(SHETC)/%.conf /home/boris/tonix/opt/shell/build/%.debug.json %.args
	tonos-cli -c $< debug run `jq -j '.config.addr' $<` -d $(word 2,$^) $f $(word 3,$^)
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
vp=~/tonix/var/log
_fl=[ -s $1 ] && tput setaf $2; cat $1 | tee -a $(vp)/$3 $(vp)/session; tput sgr0;rm -f $1

flush_std: stdout stderr
	$(if $(file <$<),$(call _fl,$<,2,stdout))
	$(if $(file <$(word 2,$^)),$(call _fl,$(word 2,$^),1,stderr))
V?=
.PHONY: clean flush_std

$(V).SILENT: run_make_cmd run_builtin run_execute_cmd run_dispose_cmd run_builtin_job exec_help exec_core exec_subr exec_pgroup env_arg %.args clean make_cmd.args execute_cmd.args dispose_cmd.args core.args help.args flush_std