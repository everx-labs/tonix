R_ROOT:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))..
export
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables --no-print-directory
NET:=rfld
#NET:=fld
#NET:=dev
GIVER:=Novi
VAL0:=15
VAL1:=1
TOOLS_BIN:=$(R_ROOT)/bin
RKEYS:=$(R_ROOT)/k1.keys
# Tools directories
SOLD:=$(TOOLS_BIN)/sold
LINKER:=$(TOOLS_BIN)/tvm_linker
TOC:=$(TOOLS_BIN)/tonos-cli

BIN:=bin
BLD:=build
ETC:=etc
#SRC:=src
TMP:=tmp

URL_dev:=net.ton.dev
URL_fld:=gql.custler.net
URL_rfld:=rfld-dapp.itgold.io
URL:=$(URL_$(NET))

#vars:   ## Values of the special variables
#	@printf "MAKEFILE_LIST: %s\nVARIABLES: %s\nFEATURES: %s\nINCLUDE_DIRS: %s\n" $(MAKEFILE_LIST) $(.VARIABLES) $(.FEATURES) $(.INCLUDE_DIRS)
#v2:     ## Values of all variables
#	$(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))
#info:   ## Local context information
#	@printf "Prime: %s\nHost: %s\nNet: %s\n" $(PRIME) $H $(NET)
#	@printf "Current: %s\nRoot: %s\nSubdirs: %s\n" $(CURDIR) $(R_ROOT) $(SUBS)
#help:   ## Show this help
#	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
#list:   ## List the existing targets
#	LC_ALL=C $(MAKE) -pRrq -f Makefile : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
