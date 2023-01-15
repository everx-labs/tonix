R_ROOT:=~/z/tonix

tools:
	$(MAKE) -f tools.mk tools

.PHONY: list cx rx sx
#.PRECIOUS: $(BIN)/*.boc
