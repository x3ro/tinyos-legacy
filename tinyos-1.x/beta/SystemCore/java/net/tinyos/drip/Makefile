TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drip
MIG = mig java
LIB = $(TOSDIR)/../beta/SystemCore

# List of message classes to build
MSGS = DripMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripMsg.java: $(LIB)/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(LIB)/Drip/Drip.h DripMsg -o $@

cleanmig:
	rm -f $(MSGS)
