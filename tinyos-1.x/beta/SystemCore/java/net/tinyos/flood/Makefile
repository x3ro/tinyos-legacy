TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.flood
MIG = mig java

# List of message classes to build
MSGS = FloodMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

FloodMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FloodMsg $(TOSDIR)/../beta/SystemCore/Flood/Flood.h FloodMsg -o $@

cleanmig:
	rm -f $(MSGS)
