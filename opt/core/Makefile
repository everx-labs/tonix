R_ROOT:=~/newdir/tonix

UTILS:=cat cp df ln ls mkdir mv realpath rm rmdir basename chfn colrm column cut diff dirname env expand fuser look lslogins lsof man paste patch pathchk printenv ps rev tail tr uname unexpand whatis whoami du file findmnt finger getent grep groups head hostid hostname id last login lsblk mountpoint namei newgrp readlink stat touch wc who
CTX:=$(UTILS)
H:=Repo

NET:=rfld
include $(R_ROOT)/Makefile.common

#URL:=$(URL_RFLD)

R:=RepoU
r:=$(OPT)/Repo/bin/$R

ETC_HOSTS:=$(ETC)/hosts.1

b1: $(patsubst %,$(MAN)/%.0,$(UTILS))
	rm -f $(MAN)/1.man
	jq 'add' $^ >$(MAN)/1.man

$(ETC)/hosts.0: $(OPT)/Repo/$(ETC)/$R.conf
	jq -r '.config.addr' $< | xargs -I{} echo -e {}'\t'$R >$@
$(ETC_HOSTS): $(ETC)/hosts.0
	head -n 1 $< >$@
	$r etc_hosts | sed 's/ *$$//' >>$@
hosts:
	rm -f $(ETC_HOSTS)
	$(MAKE) $(ETC_HOSTS)
