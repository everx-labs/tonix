
USRBINUTILS:=alias basename colrm column cut diff du env expand file finger getent getopt grep \
head id last login look man newgrp paste patch pathchk printenv rev stat tail touch tr uname unexpand wc who
BINDIR?=usr/bin

cpp: $(patsubst %,../../../src/%.sol,$(USRBINUTILS))
	cp $^ .
