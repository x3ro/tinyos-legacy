# Makefile for tools/java/net/tinyos/xnp

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.xnp
MIG = mig java

# List of message classes to build
MSGS = XnpMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

XnpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).XnpMsg XnpMsg.h XnpMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS) *class *~


