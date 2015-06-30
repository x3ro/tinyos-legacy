TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.tools
MIG = mig java

# List of message classes to build
MSGS = SimpleCmdMsg.java LogMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

SimpleCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SimpleCmdMsg $(TOS)/lib/SimpleCmdMsg.h SimpleCmdMsg >$@

LogMsg.java:
	$(MIG) -java-classname=$(PACKAGE).LogMsg $(TOS)/lib/SimpleCmdMsg.h LogMsg >$@

cleanmig:
	rm -f $(MSGS)
