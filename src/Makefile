lib-so			+= libct

obj-y			+= libct.o
obj-y			+= log.o

#
# We need protobuf
obj-e			+= $(filter-out src/protobuf/built-in.o,$(shell ls src/protobuf/*.o))

cflags-y		+= -fPIC -Wa,--noexecstack -fno-stack-protector
cflags-so		+= -rdynamic

.SECONDARY:

ifneq ($(MAKECMDGOALS),clean)
incdeps := y
endif
