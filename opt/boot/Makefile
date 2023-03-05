X:=xeen
P:=pai
L:=loader
I:=ixeen
U:=hush
H:=$P
D:=$L $L $I
CTX:=$D $H
INC_PATH+=include lib
include ../common.mk

h=ixeen
SHELL = /bin/bash

m?=complete
%: %.res
	jq -r .out $<
	printf "`tput setaf 1` `jq -r .err $<` `tput sgr0`\n"
	eval `jq -r .cmd $<`
