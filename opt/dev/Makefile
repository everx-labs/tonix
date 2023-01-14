R_ROOT:=~/tonix

#H:=dis
#H:=cview
H:=cstat
D:=cell a1 a2 a3 a4 cstat
CTX:=$H $D
NET:=rfld
#NET:=fld
include $(R_ROOT)/Makefile.common

$(SRC)/cstat.sol: $(SRC)/libdis2.sol
	@true

#tonos-cli -c etc/cstat.conf callx -m upgrade --c `cat build/cstat.cs`
run: $(ETC)/$H.conf $(BLD)/a1.xd
	$(TOC) -c $< runx -m dda --bb `cat $(word 2,$^) | xxd -c 20000 -p` | jq -r .out

run2: $(ETC)/$H.conf $(BLD)/a1.xd
	$(TOC) -c $< runx -m dda2 --bb `cat $(word 2,$^) | xxd -c 20000 -p` | jq -r .out

r2: $(ETC)/cstat.conf $(BLD)/a4.cs
	$(TOC) -c $< runx -m pcstat --c `cat $(word 2,$^)` | jq -r .out

r3: $(ETC)/cstat.conf $(BLD)/a1.cs
	$(TOC) -c $< runx -m statw --n 11 --c `cat $(word 2,$^)` | jq -r .out