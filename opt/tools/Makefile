R_ROOT:=~/tonix

TOOLS:=fsck mount reboot umount groupadd groupdel groupmod useradd userdel usermod dumpe2fs mke2fs mkfs tfs tmpfs uma_startup umm vmm vnp tucred tfiledesc subr_syscall subr_ucred subr_fdt subr_fattr subr_io subr_signal subr_proc subr_nl
#TOOLS:=tdev
CTX:=$(TOOLS)
H:=nub
NET:=rfld
include $(R_ROOT)/Makefile.common
#URL:=$(URL_RFLD)

SYS_KERN_LIB_PATH=$(CURDIR)/$(SRC)
#R:=RepoT
#r:=$(OPT)/Repo/bin/$R

#ETC_HOSTS:=$(ETC)/hosts.1

#ru:
#	$r models

# make add name=chfn
# for i in df ln ls mkdir mv realpath rm rmdir eilish; do make add dir=bin name=$i; done
# for i in cd command compgen complete declare dirs echo eilish enable exec export hash help mapfile popd pushd pwd read readonly set shift shopt source test type ulimit unalias unset esh; do make add name=$i; done
#name?=
#add: $(BLD)/$(name).cs
#	$r add_model $(name) $<
#$(STORED_IMGS):
#	$r images >$@
#images: $(STORED_IMGS)
#	@true
#$(ETC)/hosts.0: $(OPT)/Repo/$(ETC)/$R.conf
#	jq -r '.config.addr' $< | xargs -I{} echo -e {}'\t'$R >$@
#$(ETC_HOSTS): $(ETC)/hosts.0
#	head -n 1 $< >$@
#	$r etc_hosts | sed 's/ *$$//' >>$@
#hosts:
#	rm -f $(ETC_HOSTS)
#	$(MAKE) $(ETC_HOSTS)
#rstat:
#	$r stat
#tty tt: tx bocs
#	./$<
