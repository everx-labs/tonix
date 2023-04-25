M:=tulsi
T:=parsec
G:=gensec
H:=$M
D:=$H $T $M
INIT:=$D
CTX:=$D $H
include ../common.mk

SHELL = /bin/bash
DAT:=data

s?=q2
c?=ixeen
sc: $(TMP)/scan_mem.res
$(TMP)/scan_mem.res: $(DAT)/$s/$s.tin $c.ram
	$(TOC) -c $(ETC)/$G.conf runx -m scan_mem "`jq -s '{g:.[0].g,m:.[1]._ram}' $^`" | jq -r .out,.dbg

$(DAT)/$s/$s.tin: $(DAT)/$s.sol
	$(TOC) -c $(ETC)/$T.conf runx -m parse_source "`jq -cn --rawfile v $< '{name:"$s",ss:$$v}'`" >$@

sty: $(TMP)/struct_types.res
$(TMP)/struct_types.res: $(DAT)/$s/$s.tin
	$(TOC) -c $(ETC)/$G.conf runx -m struct_types "`jq '{g:.g}' $^`" | jq -r .out,.dbg

ti: $(TMP)/type_info.res
$(TMP)/type_info.res: $(DAT)/$s/$s.tin
	$(TOC) -c $(ETC)/$G.conf runx -m type_info "`jq '{g:.g}' $^`" | jq -r .out,.dbg

gm: $(DAT)/$s/$s_gen.src
$(DAT)/$s/$s_gen.src: $(DAT)/$s/tgen.cfg $(DAT)/$s/$s.tin
	$(TOC) -c $(ETC)/$G.conf runx -m gen_module "`jq --slurpfile v $< '{g:.g,h:$$v[]}' $(word 2,$^)`" | jq -r .out >$@
	$(SOLD) $@ -p $s -o $(BLD)

#	jq -r '.m["0"]' $< | xargs $(TOC) -c $(ETC)/$s.conf runx -m print --t 29 --c | jq -r .out
_test=jq -r '.m["$1"]' $< | xargs $(TOC) -c $(ETC)/$s.conf runx -m print --t $2 --c | jq -r .out
test: $(DAT)/$s/$s.tst
	$(call _test,0,29)
	$(call _test,1,33)
	$(call _test,2,34)
	$(call _test,5,28)
	$(foreach n,6 7 8 9,$(call _test,$n,27);)

run: test