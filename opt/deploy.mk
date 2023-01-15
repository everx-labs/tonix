#_pay=$(TOC) -c $(R_ROOT)/etc/$(GIVER).$(NET).conf callx -m sendTo --dest $1 --val $2
1?=
2?=
define _pay
$(TOC) -c $(R_ROOT)/etc/$(GIVER).$(NET).conf callx -m sendTo --dest $1 --val $2
endef

H?=
CTX?=
INIT?=$H
DEPLOYED=$(patsubst %,$(BLD)/%.deployed,$(INIT))
CONFD=$(patsubst %,$(ETC)/%.conf,$(CTX))
CCS=$(patsubst %,$(BLD)/%.cs,$(CTX))
CSS=$(patsubst %,$(BLD)/%.tvc,$(CTX))
RES=$(patsubst %,$(BLD)/%.ress,$(CTX))
NULL:=
SPACE:=$(NULL) $(NULL)
DIRS:=$(BLD) $(ETC)
INC_PATH?=
dirs:
	mkdir -p $(DIRS)
cs: $(CCS) ## compile source contracts to generate a cell with code
	@true
cc: $(CSS) ## compile source contracts to generate a cell with code
	@true
uc: $(BLD)/$H.cs
	$(TOC) -c $(ETC)/$H.conf callx -m uc --c $(file <$<)
clean:
	rm -f $(BLD)/*.cs
deploy: $(DEPLOYED) ## Deploy a set of contracts marked as initial
	-cat $^
config:
	$(TOC) config --url $(URL) --is_json true
ss: $(RES)
	@true
conf: $(CONFD)
	-cat $^
fk:
	touch $(RES)
$(BLD)/%.tvc: %.sol
	$(SOLD) $< $(foreach i,$(INC_PATH),-I $i) -O $(BLD)
#$(BLD)/%.cs: $(BLD)/%.tvc
$(BLD)/$H.cs: $(BLD)/$H.tvc
	$(LINKER) decode --tvc $< | grep 'code:' | cut -d ' ' -f 3 | tr -d '\n' >$@
#$(BLD)/%.cs: %.sol
#	$(SOLD) $< -O $(BLD) $(foreach i,$(INC_PATH),-I $i) --print_code >cout
#	jq -r '.code' cout >$@


$(BLD)/$H.shift: $(BLD)/$H.tvc $(RKEYS)
	$(TOC) -j genaddr $< --setkey $(word 2,$^) | jq -r '.raw_address' >$@
$(BLD)/%.cargs:
	$(file >$@,{})
$(BLD)/$H.deployed: VAL1 = 10
$(BLD)/%.deployed: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL1))
	$(TOC) -u $(URL) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@
$(BLD)/%.yes: $(BLD)/%.shift $(BLD)/%.tvc $(BLD)/%.abi.json $(RKEYS) $(BLD)/%.cargs
	$(call _pay,$(file < $<),$(VAL1))
	$(TOC) deploy $(word 2,$^) --abi $(word 3,$^) --sign $(word 4,$^) $(word 5,$^) >$@
dd_%: $(BLD)/%.tvc
	$(eval a!=$(TOC) -j genaddr $< --setkey $(RKEYS) | jq -r '.raw_address')
	$(call _pay,$a,$(VAL1))
	$(TOC) deploy $< --abi $(BLD)/$*.abi.json --sign $(RKEYS) {}
	$(TOC) -c $(ETC)/$*.conf config --url $(URL) --addr $a --abi $(CURDIR)/$(BLD)/$*.abi.json --is_json true --balance_in_tons true --project_id 2e786c9575af406fa784085c88b5e7e3 --access_key 38f728004a4b40e2a8aa30f8fee45346
name?=
val?=15
pay: $(ETC)/$(name).conf
	$(call _pay,`jq -r '.config.addr' $<`,$(val))
$(BLD)/%.ress: $(BLD)/%.cs
	$(eval args!=jq -R '{c:.}' $<)
	$(TOC) -c $(ETC)/$*.conf callx -m upgrade '$(args)' >$@
hconf: $(BLD)/$H.shift $(BLD)/$H.abi.json
	$(TOC) -c $(ETC)/$H.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(CURDIR)/$(word 2,$^) --is_json true --balance_in_tons true
dhconf: $(BLD)/$H.shift $(BLD)/$H.abi.json
	$(TOC) -c $(ETC)/$H.conf config --url $(URL) --wc 0 --addr $(file <$<) --abi $(CURDIR)/$(word 2,$^) --is_json true --balance_in_tons true --project_id 2e786c9575af406fa784085c88b5e7e3 --access_key 38f728004a4b40e2a8aa30f8fee45346 
#uc: $(BLD)/$H.cs
#	$(TOC) -c ../$(ETC)/$H.conf callx -m uc --c $(file <$<)

#$(TMP)/%.tvc: ../$(ETC)/%.conf
#	$(TOC) account `jq -r .config.addr $<` -d $@
$(TMP)/%.tvc: $(TMP)/%.boc
	$(TOC) decode account boc $< -d $@
dump_%: $(TMP)/%.tvc $(BLD)/%.abi.json
	$(TOC) decode account data --abi $(word 2,$^) --tvc $<
$(TMP)/%.boc: $(ETC)/%.conf
	$(TOC) account `jq -r .config.addr $<` -b $@
dump2_%: $(TMP)/%.boc $(BLD)/%.abi.json
	$(TOC) decode account boc $<