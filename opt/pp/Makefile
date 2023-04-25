A:=psh
B:=pp
H:=$A
D:=$A $B
INIT:=$H $B
CTX+=$D $H

T:=test2.sol

include ../common.mk

%.res: $(ETC)/%.conf
	$(TOC) -c $< runx -m main --s $T | jq -r .cmd >$@

run2: $B.res
	chmod u+x $< && ./$<
	rm -f $<

run: $(ETC)/$B.conf
	$(TOC) -c $< runx -m main --s $T | jq -r .cmd >qq && chmod u+x qq && ./qq
