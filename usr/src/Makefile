BINUTILS:=cat cp cut df echo ln ls mkdir mv ps pwd realpath rm rmdir test eilish
S:=$(BINUTILS)
BINDIR?=bin
SUBDIR+=bin
.PATH: ${SRCTOP}/bin
SRCS+=  $(BINUTILS)

worlds: .PHONY
	cd ${.CURDIR}; ${SUB_MAKE} UNIVERSE_TARGET=buildworld universe

V?=
#$(V).SILENT:

.PHONY: list cc ss hosts tt tty
