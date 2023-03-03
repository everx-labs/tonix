A:=
B:=pp
H:=$B
D:=
CTX+=$D $H

TMP:=tmp
all: dirs cc

include $(PWD)/../vars.mk
include $(PWD)/../deploy.mk

%.res: $(ETC)/%.conf
	$(TOC) -c $< runx -m main --s test.sol | jq -r .cmd >$@

run2: $B.res
	chmod u+x $< && ./$<

run: $(ETC)/$B.conf
	$(TOC) -c $< runx -m main --s test.sol | jq -r .cmd >qq && chmod u+x qq && ./qq
#up_%: $(ETC)/%.conf
#	$(TOC) -c $< runx -m action >$@
