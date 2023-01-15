define t-acc
e_$1=../$(ETC)/$1.conf
a_$1=$(TOC) -c $$(e_$1) account
r_$1=$(TOC) -c $$(e_$1) runx -m $$@
ee=$(ETC)/$$(basename $$@).conf
rr=$(TOC) -c $$(ee) runx -m $$(subst .,,$$(suffix $$@))
cc=$(TOC) -c $$(ee) callx -m $$(subst .,,$$(suffix $$@))
c_$1=$(TOC) -c $$(e_$1) callx -m $$@
p_$1=$(TOC) -c $$(e_$1) runx -m $$@ | jq -r .out
endef
$(foreach c,$(PRIME),$(eval $(call t-acc,$c)))
