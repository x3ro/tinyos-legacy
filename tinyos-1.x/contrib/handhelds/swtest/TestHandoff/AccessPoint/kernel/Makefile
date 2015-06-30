# Makefile for telos_ap kernel module

ifneq ($(KERNELRELEASE),)
obj-m	:= telos_ap.o
else
KDIR	:= /lib/modules/$(shell uname -r)/build
PWD     := $(shell pwd)

default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules

clean cleanall:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) clean

endif

