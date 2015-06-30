
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.oscope
APP = $(TOS)/../apps/Oscilloscope
MIG = mig java

# List of message classes to build
MSGS = OscopeMsg.java OscopeResetMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

OscopeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeMsg $(APP)/OscopeMsg.h OscopeMsg -o $@
	$(JAVAC) $@

OscopeResetMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeResetMsg $(APP)/OscopeMsg.h OscopeResetMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

