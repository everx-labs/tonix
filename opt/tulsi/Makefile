M:=tulsi
T:=parsec
G:=gensec
P:=pav
H:=$P
D:=$H $T $M $G
INIT:=$D
CTX:=$D $H
include ../common.mk

SHELL = /bin/bash
DAT:=data

check:
	$(TOC) -c $(ETC)/$M.conf runx -m onc --h 0x0000000000000000000000000000000000000000000000000000000000020000 --s 2

V1=R_PATH TOOLS_BIN RKEYS SOLD LINKER TOC BIN BLD ETC TMP URL DEPLOYED INSTALLED CONFD CCS CSS ASM ABI INC_PATH
V2=../.. bin k1.keys sold tvm_linker tonos-cli bin build etc tmp rfld-dapp.itgold.io ployed installed conf cs tvc code abi.json .
V3=Root Tools Keys Compiler Linker TOC Binary Build Config Temp URL Depld Instd Config Code StateInit Assembly JSON Headers
comma=,
null=
space=$(null) $(null)
_toa=$(subst $(space),,["$(firstword $1)"$(patsubst %,$(comma)"%",$(wordlist 2,$(words $1),$1))])

define t-enc
enc_$4:
	$(TOC) -c $(ETC)/$M.conf callx -m st --a $4 --c `$$(call _enp,$1,$2,$3)`
endef

#$(info $(call t-enc,$(V1),$(V2),$(V3),33))
$(eval $(call t-enc,$(V1),$(V2),$(V3),33))
$(eval $(call t-enc,PROJ,awt,Client,36))
$(eval $(call t-enc,PARSER FN,parsec parse_source,parser worker,38))
$(eval $(call t-enc,MODULE,rt,MODULE,42))

3?=
_enp=$(TOC) -c $(ETC)/$M.conf runx -m enp --ss1 $(call _toa,$1) --ss2 $(call _toa,$2) --ss3 $(call _toa,$3) | jq -r .c

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