# set this to arm-linux to compile for iPaqs
ARCH:=i686-linux
#ARCH:=arm-linux

ARM_LINUX_ROOT    := /usr/local/lecs/arm-linux

MY_INCLUDES := -Wall -DNOT_IN_TOS -DDEFAULT_LOCAL_GROUP=0x7d -I$(TOSDIR)/system -I../../tos/system -I../../tos/lib -I../../tos/platform/mica

ifeq ($(ARCH), arm-linux)
	KERNEL_INCLUDE := $(ARM_LINUX_ROOT)/src/kernel/$(ARM_KERNEL_VERSION)/include
	LIBPATH += -L$(ARM_LINUX_ROOT)/arm-linux/lib
	CPP := $(ARM_LINUX_ROOT)/bin/arm-linux-g++
	CC := $(ARM_LINUX_ROOT)/bin/arm-linux-gcc
	AR := $(ARM_LINUX_ROOT)/bin/arm-linux-ar
	LD := $(ARM_LINUX_ROOT)/bin/arm-linux-ld
	BINSTRIP := $(ARM_LINUX_ROOT)/bin/arm-linux-strip
	SHLIBPATH := $(ARM_LINUX_ROOT)/arm-linux/lib
	SHUSRLIBPATH := $(ARM_LINUX_ROOT)/arm-linux/lib
	CFLAGS = $(MY_INCLUDES) -DARM_LINUX

else

	CFLAGS = $(MY_INCLUDES)
endif

TARGETS = diffdump  beacondump diffsink

all: $(TARGETS)

clean:
	rm -rf *.o $(TARGETS)

distclean: clean
	rm -rf *~
