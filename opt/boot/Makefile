X:=xeen
P:=gpart
L:=bsdlabel
I:=image
U:=ufsd
E:=dump
N:=newfs
M:=ixeen
W:=iii
H:=$M
D:=$L $L $I $E $U $M
CTX:=$D $H
INC_PATH+=include lib
include ../common.mk

#h=ixeen
SHELL = /bin/bash

h?=0
s?=0
$(TMP)/$M_onc.arg: uf
	jq -c '{h:$h,s:"$s",udin:.}' $< >$@
$(TMP)/$M_onc.res: $(ETC)/$M.conf $(TMP)/$M_onc.arg
#	$(TOC) -c $< runx -m onc '`cat $(word 2,$^)`' >$@
	$(TOC) -c $< runx -m onc '$(file <$(word 2,$^))' >$@

m?=complete
%: %.res
	jq -r .out $<
	printf "`tput setaf 1` `jq -r .err $<` `tput sgr0`\n"
	eval `jq -r .cmd $<`

SOLC:=~/git/sol2tvm/build/solc/solc
f=iii
ck:
	$(SOLC) --base-path . --include-path include --include-path lib $f.sol
	$(LINKER) compile --lib ~/git/sol2tvm/pub/lib/stdlib_sol.tvm $f.code -o $f.tvc
	$(LINKER) test $f --gas-limit 1000000 --abi-json $f.abi.json --abi-method constructor --abi-params {}
	$(LINKER) test $f --decode-c6 --gas-limit 100000000 --abi-json $f.abi.json --abi-method onc --abi-params '{"h":0,"s":"1","udin":{"name":"\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000","ufs":"1","fd":"0","bsize":"124","sblock":"4","si":"6","inoblock":"18","inomin":"0","inomax":"0","dp":"0","fs":{"sblkno":"4","cblkno":"6","iblkno":"18","dblkno":"82","ncg":"4","bsize":"124","maxcontig":"16","maxbpg":"250","fsbtodb":"8","id":"514","sbsize":"31","cssize":"5","cgsize":"31","inosize":"20","desize":"7","inopb":"6","ipg":"96","cs":{"ndir":"0","nbfree":"918","nifree":"384"},"flags":"1","fs_fsmnt":"0","volname":"0","time":"1680697326","size":"1000","dsize":"918","magic":"17222"},"cg":{"g":{"cgx":"0","cs":{"ndir":"0","nbfree":"168","nifree":"96"},"ndblk":"0","iusedoff":"14","freeoff":"10","niblk":"18","rotor":"0","irotor":"0","nextfreeoff":"82","initediblk":"0","unrefs":"0","space":"0","magic":"17223"},"nino":"0","nblk":"82","inobmp":"0","bbmp":"4835703278458516698824703"},"ccg":"0","lcg":"0","error":"","sblockloc":"4","lookupflags":"0","mine":"0"}}'
