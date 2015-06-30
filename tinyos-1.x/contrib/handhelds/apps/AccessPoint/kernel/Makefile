# Makefile for span_ap kernel module

ifneq ($(KERNELRELEASE),)
obj-m	:= span_ap.o
else
KDIR	:= /lib/modules/$(shell uname -r)/build
PWD     := $(shell pwd)

LINUX_VERSION := $(shell uname -r)

ifeq ($(shell /usr/bin/expr $(LINUX_VERSION) ">=" 2.6.31),1)
ifeq ($(shell /usr/bin/expr $(LINUX_VERSION) "<" 2.6.31.5),1)
$(error Module fails with version $(LINUX_VERSION) >= 2.6.31 && < 2.6.31.5)
endif
endif

ifeq ($(shell /usr/bin/expr $(LINUX_VERSION) "<" 2.6.15),1)
$(warning Using older (< 2.6.15) kernel definition $(LINUX_VERSION))
FLAGS = -DKERNEL_2_6_15_OR_LESS
endif

ifeq ($(shell /usr/bin/expr $(LINUX_VERSION) ">" 2.6.18),1)
$(warning Using newer (> 2.6.18) kernel definition $(LINUX_VERSION))
FLAGS = -DKERNEL_2_6_19_OR_NEWER
endif

ifeq ($(shell /usr/bin/expr $(LINUX_VERSION) ">=" 2.6.24),1)
$(warning Using newer (<= 2.6.24) kernel definition $(LINUX_VERSION))
FLAGS = -DKERNEL_2_6_24_OR_NEWER
endif


default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) EXTRA_CFLAGS=$(FLAGS) modules

clean cleanall:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) clean

endif

