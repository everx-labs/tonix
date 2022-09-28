R_ROOT:=~/tonix
#H:=Repo
H:=nub
HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset jobs fg kill disown
CTX:=$(HELP_TOPICS) esh josh make_cmd execute_cmd dispose_cmd ash ish

HC:=$(R_ROOT)/opt/etc/root1.xconf
NET:=rfld
include $(R_ROOT)/Makefile.common

#URL:=$(URL_RFLD)

R:=Repo
r:=$(OPT)/$R/bin/$R

b0: $(patsubst %,$(MAN)/%.0,$(HELP_TOPICS))
	rm -f $(MAN)/0.man
	jq 'add' $^ >$(MAN)/0.man

#tty tt: tx bocs
#	./$<

$(ETC)/help.main.arg: /home/boris/tonix/usr/share/man/0.man
	jq -s '{help_files: .}' $< >$@
V:=1
$(V).SILENT: