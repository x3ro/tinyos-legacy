TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.omnisound
MIG = mig java
JAVA = javac

# List of message classes to build
MSGS = TimestampMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

TimestampMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TimestampMsg ./Omnisound.h TimestampMsg >$@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

