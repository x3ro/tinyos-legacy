TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.deluge
MIG = mig java	
LIB=$(TOSDIR)/../beta/SystemCore

# List of message classes to build
MSGS = DripMsg.java NamingMsg.java NetProgCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

NetProgCmdMsg.java: $(LIB)/DelugeMonitor/DelugeControl.h
	$(MIG) -java-classname=$(PACKAGE).NetProgCmdMsg $(TOSDIR)/../beta/SystemCore/DelugeMonitor/DelugeControl.h NetProgCmdMsg -o $@

NamingMsg.java: $(LIB)/AM/AMNamingMsg.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(TOSDIR)/../beta/SystemCore/AM/AMNamingMsg.h NamingMsg -o $@

DripMsg.java: $(LIB)/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(TOSDIR)/../beta/SystemCore/Drip/Drip.h DripMsg -o $@

cleanmig:
	rm -f $(MSGS)
