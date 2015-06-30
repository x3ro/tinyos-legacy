PACKAGE = net.tinyos.matchbox
OTHER_CLEAN = cleanmig
APP=$(shell ncc -print-tosdir)/lib/FS

MIG = mig -I%T/lib/FS java
NCG = ncg -I%T/lib/FS java

MSGS = FSOpMsg.java FSReplyMsg.java FS.java
INITIAL_TARGETS = $(MSGS)

SUBDIRS = tools

ROOT = ../../..
include $(ROOT)/Makefile.include

FSOpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FSOpMsg $(APP)/Remote.nc FSOpMsg -o$@

FSReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FSReplyMsg $(APP)/Remote.nc FSReplyMsg -o$@

FS.java:
	$(NCG) -java-classname=$(PACKAGE).FS $(APP)/Remote.nc Matchbox.h Remote.h -o$@

cleanmig:
	rm -f $(MSGS)

