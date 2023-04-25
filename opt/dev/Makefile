H:=cstat
V:=cview
D:=cell a1 a2 a3 a4 cstat $V
CTX:=$H $D
INIT:=$H $V
INC_PATH+=../include ../../usr/include ../../usr/src/lib
include ../common.mk

cstat.sol: libdis2.sol
	@true

$(BLD)/a1.xd: $(BLD)/a1.cs
	base64 -d $< | xxd -p -c 20000 >$@
r2: $(ETC)/$V.conf $(BLD)/a1.xd
	$(TOC) -c $< runx -m dda --bb `cat $(word 2,$^)` | jq -r .out

run: $(ETC)/cstat.conf $(BLD)/a3.cs
	$(TOC) -c $< runx -m pcstat --c `cat $(word 2,$^)` | jq -r .out

run2: $(ETC)/cstat.conf $(BLD)/a1.cs
	$(TOC) -c $< runx -m statw --n 11 --c `cat $(word 2,$^)` | jq -r .out
