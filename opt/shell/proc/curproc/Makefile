
tm=tonos-cli -c /home/boris/tonix/opt/shell/etc/make_cmd.conf
make_cmd.out: make_cmd.args
	$(tm) runx -m store_input $< >$@
in?=
make_cmd.args: shell_env
	jq --arg v $(in) '{e_in:.,input:$v}' $< >$@
#execute_cmd.args
#cd /home/boris/tonix/opt/shell/proc/curproc
esh.args2: shell_env
	jq --arg v "$(in)" '{e_in:.,input:$$v}' $< >$@
esh_store.out: esh.args2
	tonos-cli -c /home/boris/tonix/opt/shell/etc/esh.conf runx -m store_input $< >$@
esh.args: esh_store.out /home/boris/tonix/usr/share/optstring
	jq --slurpfile v1 $(word 2,$^) '{e_in:.e,optstring:$$v1[]}' $< >$@
esh.out: esh.args
	tonos-cli -c /home/boris/tonix/opt/shell/etc/esh.conf runx -m parse_input $< | jq '.e' >$@
	jq -er '."Error"? // empty' $@ && exit $?
#	[ -s $@ ] && cp $@ shell_env
	jq -r '.environ[30][0]' $@ >cmdline
	jq -r '.environ[23][0]' $@ | cut -d '=' -f 2 >comm
	cd /home/boris/tonix/opt/shell
	. proc/curproc/cmdline

stdout: shell_env_out
	jq -rj '.ofiles[1].buf.buf' $< | xxd -p -r >$@
stderr: shell_env_out
	jq -rj '.ofiles[2].buf.buf' $< | xxd -p -r >$@
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
vp=~/tonix/var/log
flush_std: stdout stderr
	[ -s $< ] && echo "${GREEN}$(cat $< | tee -a $(vp)/stdout $(vp)/session)${NC}" && rm $<
	[ -s $(word 2,$^) ] && echo "${RED}$(cat $(word 2,$^) | tee -a $(vp)/stderr $(vp)/session)${NC}" && rm $(word 2,$^)