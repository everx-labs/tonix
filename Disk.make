n?=4
rd: $(SYS)/$T/_disks.out $(BLD)/$S.abi.json
	$(TOC) -j run `jq -r '._disks["$n"]' <$<` --abi $(word 2,$^) _storage {} | jq -r '._storage[]' | xxd -p -r

$(SYS)/$S/addrs: $(SYS)/$S/disks
#	jq -r '._disks[]' <$< >$@
	$(eval keys:=$(shell jq -r 'keys' <$<))
	echo $(keys)
	$(foreach d,$(keys),$(shell jq -r '.[$d]' <$< >$(SYS)/$S/addr.$d))

$(SYS)/$S/addr.%: $(SYS)/$S/disks
	$(eval keys!=jq -r 'to_entries[] | .key' <$<)
	echo $(keys)
	$(foreach d,$(keys),jq -r '.["$d"]' <$< >$(SYS)/$S/addr.$d;)

_t=updateImage dd
$(foreach c,$(_t),$(eval $(call t-call,$T,$c)))

wr: $(SYS)/$T/_disks.out $(BLD)/$S.abi.json $(SYS)/$S/write.args
	$(TOC) call `jq -r '._disks["$n"]' <$<` --abi $(word 2,$^) write $(word 3,$^)

$(SYS)/$S/disks: $(SYS)/$T/_disks.out
	jq -r '._disks' <$< >$@
list: $(SYS)/$S/disks
	jq -r 'to_entries[] | .key,.value' <$< >$@
addr: $(SYS)/$S/disks
	jq -r '.[]' <$<
dsk:=$(file <$(SYS)/$S/disks)

#ff=$(SRC)/$S.sol
ft?=1

sources:=$(patsubst $(SRC)/%.sol,%,$(wildcard $(SRC)/*.sol))
ss:
	echo $(sources)

upi: $(SYS)/$T/updateImage.res
	echo $^
dd.$n: $(SYS)/$T/dd.res
	grep '\"addr\"' $<
	grep '\"addr\"' $< | xargs echo | cut -d ' ' -f 2 >$(SYS)/$S/addr.$n
$(SYS)/$S/addr.$n: $(SYS)/$T/dd.res
	grep '\"addr\"' $< | xargs echo | cut -d ' ' -f 2 >$@
SSS:=$(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.sol)) $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.c))
etc/ref.$n: $(patsubst %,$(SRC)/%,$(SSS))
	du -B16k $^ >l1
	du -b $^ >l2
	join -j 2 l1 l2 >l3
	rm -f l5
	touch l5
	$(foreach s,$^,echo $s $(call _hex,$(notdir $s)) >>l5;)
	join -j 1 l3 l5 >l6
	wc -l l6 | cut -d ' ' -f 1 | xargs seq >l7
	paste -d ' ' l7 l6 >l8
	sed -i -e 's/src\///g' l8
	cp l8 $@
	rm -f l2 l1 l3 l5 l6 l7 l8

#make fs/4
$(FS)/$n: etc/ref.$n
	-mkdir -p $@
	$(eval files!=cat $< | cut -d ' ' -f 2)
	$(foreach f,$(files),split -d --number=l/`grep ' $f ' $< | cut -d ' ' -f 3` $(SRC)/$f $f.;)
	mv *.0* $@
	rm -f $(SYS)/$T/dd.res

CCC:=$(wildcard $(FS)/$n/*.00)
$(FS)/$n/%.creat.args: etc/ref.$n $(CCC)
	$(eval filename:=$(notdir $*))
	$(eval nBlocks!=grep $(SRC)/$(filename) $< | cut -d ' ' -f 2)
	$(eval filesize!=grep $(SRC)/$(filename) $< | cut -d ' ' -f 3)
	$(file >$@,$(call _args,filetype filename nBlocks filesize,$(ft) $(call _hex,$(filename)) $(nBlocks) $(filesize)))

$(FS)/$n/%.creat: $(FS)/$n.addr $(BLD)/$S.abi.json $(FS)/$n/%.creat.args
	$(TOC) call $(file <$<) --abi $(word 2,$^) creat $(word 3,$^)
#make creat
creat: dd.$n $(patsubst %.aa,%.creat,$(CCC))
	echo $^
$(FS)/$n/out/fi: $(SYS)/$S/addr.$n $(BLD)/$S.abi.json
	mkdir -p $(FS)/$n/out
	$(TOC) -j run $(file <$<) --abi $(word 2,$^) _fi {} | jq -r '._fi' >$@

lfn: $(FS)/$n/out/fi
#	$(TOC) -j run $(file <$<) --abi $(word 2,$^) _fi {} | jq -r '._fi["$i"]'
	jq -r '.[].filename' <$< | xxd -p -r
$(FS)/$n/out/st: $(SYS)/$S/addr.$n $(BLD)/$S.abi.json
	mkdir -p $(FS)/$n/out
	$(TOC) -j run $(file <$<) --abi $(word 2,$^) _storage {} | jq -r '._storage' >$@
$(FS)/$n/out/index: $(FS)/$n/out/done
	jq -r '.inode' <$< >$@
$(FS)/$n/out/index2: $(FS)/$n/out/done
	jq -r '.inode' <$< >i1
	jq -r '.filename' <$< | xxd -p -r >i2
	paste i1 i2 >$@
	rm i1 i2
check: $(FS)/$n/out/index $(FS)/$n/out/index2 $(FS)/$n/out/done
	cat $(word 1,$^)
	cat $(word 2,$^)
#make get
get: $(FS)/$n/out/st $(FS)/$n/out/index $(FS)/$n/out/index2
	$(eval inodes:=$(strip $(file < $(word 2,$^))))
	$(foreach i,$(inodes),$(shell jq -r -S '.["$i"][]?' <$< | xxd -r -p > $(FS)/$n/out/$(shell grep $i $(word 3, $^) | cut -f 2)))


%.write: $(FS)/$n/%.inode $(FS)/$n.addr $(BLD)/$S.abi.json
	$(eval id:=$(file <$<))
	$(eval parts:=$(wildcard $(FS)/$n/$*.0*))
	$(foreach p,$(parts),$(file >$p.args,$(call _args2,id data,$(id) ["$(call _hex2,$p)"])))

#make args
args: $(patsubst %,%.write,$(SSS))
	echo $^

#make write.$n
write.$n: $(SYS)/$S/addr.$n $(BLD)/$S.abi.json args $(wildcard $(FS)/$n/*.args)
	$(eval args:=$(wordlist 4,$(words $^),$^))
	$(foreach a,$(args),$(TOC) call $(file <$<) --abi $(word 2,$^) write $a;)

_f=grep ' $1 ' $< | cut -d ' ' -f $2
$(FS)/$n/open_all.args: etc/ref.$n $(CCC)
	$(eval args:=$(wordlist 2,$(words $^),$^))
	$(foreach a,$(args),\
		$(eval fn:=$(basename $(notdir $a))) $(eval ord!=grep ' $(fn) ' $< | cut -d ' ' -f 1)\
		$(eval nblk!=grep ' $(fn) ' $< | cut -d ' ' -f 3) $(eval fsize!=grep ' $(fn) ' $< | cut -d ' ' -f 4) \
		$(eval aas+=$(call _args,ord filename nblk fsize,$(ord) $(call _hex,$(fn)) $(nblk) $(fsize))))
	$(eval asss:=[$(subst }$(space){,}$(comma){,$(aas))])
	$(file >$@,$(call _args2,filetype fins,1 $(asss)))
#	}

$(FS)/$n/open_all.res: $(SYS)/$S/addr.$n $(BLD)/$S.abi.json $(FS)/$n/open_all.args
	$(TOC) call $(file <$<) --abi $(word 2,$^) open_all $(word 3,$^) >$@

oargs: $(FS)/$n/open_all.args
	echo $^

openall: $(FS)/$n/open_all.res
	echo $^

%.write_fd: $(FS)/$n/%.00 etc/ref.$n $(FS)/$n/fd.map
	$(eval ord!=grep ' $* ' $(word 2,$^) | cut -d ' ' -f 1)
	$(eval fd!=grep '\"$(ord)\" ' $(word 3,$^) | cut -d ' ' -f 2 | tr -d '\"')
#	echo $* ORD $(ord) FD $(fd)
	$(eval parts:=$(wildcard $(FS)/$n/$*.0*))
	$(foreach p,$(parts),$(file >$p.args,$(call _args2,fd part data,$(fd) $(subst .0,,$(suffix $p)) "$(call _hex2,$p)")))

$(FS)/$n/fd.map: $(FS)/$n/open_all.res
	cp $< b0
	grep -A 100 'Result:' b0 >b1
	sed -i -e 's/Result: //g' b1
	jq -r '.fds' <b1 >b2
	jq 'to_entries[] | .key,.value' <b2 >b3
	paste -d " " - - <b3 >$@
	rm -f b0 b1 b2 b3

args_fd: $(patsubst %,%.write_fd,$(SSS))
	echo $^

write_fd.$n: $(SYS)/$S/addr.$n $(BLD)/$S.abi.json $(wildcard $(FS)/$n/*.args)
	$(eval args:=$(wordlist 3,$(words $^),$^))
	$(foreach a,$(args),$(TOC) call $(file <$<) --abi $(word 2,$^) write_fd $a;)

$(FS)/$n/out/list: $(SYS)/$S/_fdes.out
	mkdir -p $(FS)/$n/out
	jq -r '._fdes[] | select(.mode=="65") .filename' <$< | xxd -p -r
$(FS)/$n/out/done: $(SYS)/$S/_fdes.out
	mkdir -p $(FS)/$n/out
	jq -r '._fdes[] | select(.mode=="65")' <$< >$@

$(SYS)/$T/%.out:
	 $(TOC) -j run $(file < $(SYS)/$T/address) --abi $(BLD)/$T.abi.json $* {} | jq -r '.' >$@
$(SYS)/$S/%.out:
	 $(TOC) -j run $(file < $(SYS)/$S/addr.$n) --abi $(BLD)/$S.abi.json $* {} | jq -r '.' >$@

df: $(SRC)/df.c
	gcc $< -o $@

$(FS)/%.addr: $(SYS)/$S/addr.%
	cp $^ $@

$(FS)/%.out: $(FS)/$n.addr $(BLD)/$S.abi.json $(SSS)
	$(TOC) -j run $(file <$<) --abi $(word 2,$^) _fi {} | jq '._fi[].filename' | xxd -p -r
$(FS)/%.ref: $(FS)/$n.addr $(BLD)/$S.abi.json $(SSS)
	$(if $(findstring $*,$(TOC) -j run $(file <$<) --abi $(word 2,$^) _fi {} | jq '._fi[].filename' | xxd -p -r),$(file >$@,)

ty: bin/df
	./$<
