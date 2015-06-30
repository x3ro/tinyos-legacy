
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.oscope
MIG = mig java

# List of message classes to build
MSGS = OscopeMsg.java OscopeResetMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

OscopeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeMsg $(TOS)/lib/OscopeMsg.h OscopeMsg >$@

OscopeResetMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeResetMsg $(TOS)/lib/OscopeMsg.h OscopeResetMsg >$@

cleanmig:
	rm -f $(MSGS)

