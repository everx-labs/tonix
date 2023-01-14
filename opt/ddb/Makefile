R_ROOT:=~/tonix

H:=main
D:=
S:=sone
C:=cvt2
CTX:=$H $D
NET:=rfld
#NET:=fld
include $(R_ROOT)/Makefile.common

HCC?=$(BUS)/$(ETC)/rob0.conf

$(BLD)/%.shift: $(BLD)/%.tvc $(RKEYS)
	$(TOC) -j genaddr $< --setkey $(word 2,$^) | jq -r '.raw_address' >$@
$(BLD)/%.cargs:
	$(file >$@,{})
$(BLD)/%.deployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL0))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@
$(BLD)/%.ress: $(BLD)/%.cs
	$(eval args!=jq -R '{c:.}' $<)
	$(TOC) -c $(ETC)/$*.conf callx -m upgrade '$(args)' >$@
hconf: $(BLD)/$H.shift $(BLD)/$H.abi.json
	$(TOC) -c $(ETC)/$H.conf config --url $(URL) --addr $(file <$<) --abi $(CURDIR)/$(word 2,$^) --is_json true --balance_in_tons true
$(ETC)/nub.conf:
	@true

if?=el0.jpg
slc: $(ETC)/$S.conf $(if)
	$(TOC) -c $< runx -m slice --data `cat $(word 2,$^) | xxd -p -c 2000000` >res
	$(eval f:=$(notdir $(word 2,$^)))
	jq '.uio' res >$f.uio
	jq '.cells' res >$f.cells
	$(eval l!=jq '. | length' $f.cells | xargs -I {} echo {} | bc)
	$(foreach i,$(shell seq 1 $l),$(TOC) -c $< callx -m store_cell -- --addr $i --c `jq -r --arg x $i '.[$$x]' $f.cells`;)

out_b64.%: $(ETC)/$S.conf $(ETC)/$C.conf %.uio
#	($(foreach i,$(shell jq -r '.uio_iov[] | .iov_base' $<),$(TOC) -c $(ETC)/sone.conf runx -m read_cell -- --addr $i | jq -rj '.value0' >>$@;))
	($(foreach i,$(shell jq -r '.uio_iov[] | .iov_base' $(word 3,$^)),$(TOC) -c $< runx -m read_cell -- --addr $i | jq '{c:.value0}' >args && $(TOC) -c $(word 2,$^) runx -m c2b args | jq -rj '.out' >>$@;))
out.%: out_b64.%
	xxd -p -r $< >$@
v_%: out.%
	feh $<

uc: $(BLD)/$H.cs $(HCC)
	$(eval args!=jq -R '{c:.}' $<)
	$(TOC) -c $(word 2,$^) callx -m upgrade '$(args)'

