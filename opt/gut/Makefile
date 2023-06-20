L:=gen
O:=par
C:=check
H:=$L
D:=$H $L $O $C
#INIT:=$D
INIT:=$H
CTX:=$D $H

include ../common.mk

SHELL = /bin/bash
DAT:=data

s?=rt
$(DAT)/$s/$s.tin: $(DAT)/$s.sol
	$(TOC) -c $(ETC)/$O.conf runx -m parse_source "`jq -cn --rawfile v $< '{name:"$s",ss:$$v}'`" >$@

ck: $(DAT)/$s/$s.tin
	$(TOC) -c $(ETC)/$C.conf runx -m tcheck "`cat $<`" | jq -r .out

$(TMP)/gen_lib.res: $(DAT)/$s/$s.tin
	$(TOC) -c $(ETC)/$L.conf runx -m gen_lib "`cat $<`" >$@
$(TMP)/$L_gen.src: $(TMP)/gen_lib.res
	$(TOC) -c $(ETC)/$C.conf runx -m meld -- "`jq {lines:.res} $<`" | jq -r .out >$@
lgc: $(TMP)/$L_gen.src
	$(SOLD) $< -o $(TMP)

c?=
run:
	$(TOC) -c $(ETC)/$C.conf runx -m cmd --ss "$c" | jq -r .res[] >/tmp/scr
	source /tmp/scr