MAKEFLAGS 	:= -r -R --no-print-directory

ifeq ($(strip $(V)),)
	E = @echo
	Q = @
else
	E = @\#
	Q =
endif

FIND		:= find
CSCOPE		:= cscope
TAGS		:= ctags
RM		:= rm -f
CP		:= cp
LD		:= ld
CC		:= gcc
CD		:= cd
ECHO		:= echo
NM		:= nm
AWK		:= awk
SH		:= bash
MAKE		:= make
OBJCOPY		:= objcopy
MKDIR		:= mkdir
LN		:= ln
ESED		:= esed
SED		:= sed
CAT		:= cat

#
# Fetch ARCH from the uname if not yet set
#
ARCH ?= $(shell uname -m | sed		\
		-e s/i.86/i386/		\
		-e s/sun4u/sparc64/	\
		-e s/arm.*/arm/		\
		-e s/sa110/arm/		\
		-e s/s390x/s390/	\
		-e s/parisc64/parisc/	\
		-e s/ppc.*/powerpc/	\
		-e s/mips.*/mips/	\
		-e s/sh[234].*/sh/)

ifeq ($(ARCH),x86_64)
	ARCH         := x86
	DEFINES      := -DCONFIG_X86_64 -DARCH="\"$(ARCH)\""
	LDARCH       := i386:x86-64
endif

ifneq ($(ARCH),x86)
$(error "The architecture $(ARCH) isn't supported"))
endif

cflags-y	+= -iquote src/include
cflags-y	+= -fno-strict-aliasing
cflags-y	+= -I/usr/include
export cflags-y

VERSION_MAJOR		:= 0
VERSION_MINOR		:= 1
VERSION_SUBLEVEL	:= 0
VERSION_EXTRA		:=
VERSION_NAME		:=

export VERSION_MAJOR VERSION_MINOR VERSION_SUBLEVEL VERSION_EXTRA VERSION_NAME

include scripts/Makefile.version
include scripts/Makefile.config

LIBS		:= -lrt -lprotobuf-c

DEFINES		+= -D_FILE_OFFSET_BITS=64
DEFINES		+= -D_GNU_SOURCE

WARNINGS	:= -Wall

ifneq ($(WERROR),0)
	WARNINGS += -Werror
endif

ifeq ($(DEBUG),1)
	DEFINES += -DCR_DEBUG
	CFLAGS	+= -O0 -ggdb3
else
	CFLAGS	+= -O2
endif

CFLAGS		+= $(WARNINGS) $(DEFINES)

export E Q CC ECHO MAKE CFLAGS LIBS ARCH DEFINES MAKEFLAGS
export SH RM OBJCOPY LDARCH LD CP MKDIR CD LN
export ESED SED CAT

include scripts/Makefile.rules

build := -r -R --no-print-directory -f scripts/Makefile.build makefile=Makefile obj
run := -r -R --no-print-directory

PROGRAM		:= libct.so

.PHONY: all clean tags docs

cflags-y += -iquote src/include
cflags-y += -iquote src/arch/$(ARCH)/include
export cflags-y

#
# First order targets, usually pregenerated
EARLY-GEN := $(VERSION_HEADER) config

#
# Protobuf data, shared across library
# and executable tool
src/protobuf/%:
	$(Q) $(MAKE) $(build)=src/protobuf $@
src/protobuf/built-in.o:
	$(Q) $(MAKE) $(build)=src/protobuf all

#
# Executable tool
ETOOL := etool

LDFLAGS += -L$(shell pwd)

src/exec/%: src/protobuf/built-in.o
	$(Q) $(MAKE) $(build)=src/exec $@
src/exec/built-in.o: src/protobuf/built-in.o
	$(Q) $(MAKE) $(build)=src/exec all
src/exec/$(ETOOL): src/exec/built-in.o $(PROGRAM) src/protobuf/built-in.o
	$(E) "  LINK    " $@
	$(Q) $(CC) $(CFLAGS) $^ $(LIBS) $(LDFLAGS) -lct -o $@

#
# Library itself
src/%: $(EARLY-GEN) | src/protobuf/built-in.o
	$(Q) $(MAKE) $(build)=src $@
src/built-in.o: $(EARLY-GEN) | src/protobuf/built-in.o
	$(Q) $(MAKE) $(build)=src all

$(PROGRAM): src/$(PROGRAM)
	$(E) "  LN      " $@
	$(Q) $(LN) -s $^ $@

all: $(PROGRAM) src/exec/$(ETOOL)
	@true

docs:
	$(Q) $(MAKE) -s -C Documentation all

tags:
	$(E) "  GEN     " $@
	$(Q) $(RM) tags
	$(Q) $(FIND) -L . -name '*.[hcS]' ! -path './.*' -print | xargs ctags -a

clean:
	$(Q) $(MAKE) $(build)=src clean
	$(Q) $(MAKE) $(build)=src/exec clean
	$(Q) $(MAKE) $(build)=src/protobuf clean
	$(Q) $(MAKE) -s -C Documentation clean
	$(Q) $(RM) $(PROGRAM)
	$(Q) $(RM) src/exec/$(ETOOL)
	$(Q) $(RM) $(CONFIG)
	$(Q) $(RM) $(VERSION_HEADER)

.DEFAULT_GOAL := all
