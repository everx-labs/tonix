M:=mesh
S:=settings
A:=anset
T:=tup
H:=$T
D:=$A $S $M $T
INIT:=$D
CTX+=$D $H
#NET:=fld


include ../common.mk

SHELL = /bin/bash
.ONESHELL:
run3: g.sh
	. $<
run2: f.sh
	. $<
run: g.sh
	. $<
setup: h.sh
	. $<
