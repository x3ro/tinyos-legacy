TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.radio
MIG = mig java	

# List of message classes to build
MSGS = DripMsg.java NamingMsg.java RadioControlCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

RadioControlCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).RadioControlCmdMsg $(TOSDIR)/../beta/SystemCore/AM/RadioControl.h RadioControlCmdMsg -o $@

NamingMsg.java: $(TOSDIR)/../beta/SystemCore/AM/AMEnhanced.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(TOSDIR)/../beta/SystemCore/AM/AMNamingMsg.h NamingMsg -o $@

DripMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(TOSDIR)/../beta/SystemCore/Drip/Drip.h DripMsg -o $@

cleanmig:
	rm -f $(MSGS)
