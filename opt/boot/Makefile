X:=xeen
P:=gpart
L:=bsdlabel
I:=image
U:=ufsd
E:=dump
N:=newfs
M:=ixeen
H:=$M
D:=$L $L $I $E $U
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
