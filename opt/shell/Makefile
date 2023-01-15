HELP_TOPICS:=alias builtin cd command compgen complete declare dirs echo eilish enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset jobs fg kill disown
CTX:=$(HELP_TOPICS) esh josh make_cmd execute_cmd dispose_cmd ash ish
INC_PATH+=../../usr/include ../../usr/src/lib ../../usr/src/sys/sys
include $(PWD)/../vars.mk
include $(PWD)/../deploy.mk

MAN:=../../usr/share/man
b0: $(patsubst %,$(MAN)/%.0,$(HELP_TOPICS))
	rm -f $(MAN)/0.man
	jq 'add' $^ >$(MAN)/0.man
$(ETC)/help.main.arg: $(MAN)/0.man
	jq -s '{help_files: .}' $< >$@
V:=1
$(V).SILENT: