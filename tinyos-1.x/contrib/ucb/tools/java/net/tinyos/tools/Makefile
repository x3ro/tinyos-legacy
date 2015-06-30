TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.tools
MIG = mig java

# List of message classes to build
MSGS = DripMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

DripMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DripMsg ../../../../../tos/lib/Drip/Drip.h DripMsg -o $@

cleanmig:
	rm -f $(MSGS)
