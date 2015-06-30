
TOS = $(shell ncc -print-tosdir)
PACKAGE = com.moteiv.oscope
APP = $(TOS)/../apps/Oscilloscope
MIG = mig java -I$(TOSDIR)/lib/CC2420Radio/ -target=telos 

# List of message classes to build
MSGS = OscopeMsg.java OscopeResetMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

JAVAC = javac -sourcepath ../../../

OscopeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeMsg $(APP)/OscopeMsg.h OscopeMsg -o $@
	$(JAVAC) $@

OscopeResetMsg.java:
	$(MIG) -java-classname=$(PACKAGE).OscopeResetMsg $(APP)/OscopeMsg.h OscopeResetMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

