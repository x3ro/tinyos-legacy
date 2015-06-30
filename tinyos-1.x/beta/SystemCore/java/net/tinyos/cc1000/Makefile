TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.cc1000
MIG = mig java	
LIB=$(TOSDIR)/../beta/SystemCore

# List of message classes to build
MSGS = DripMsg.java NamingMsg.java CC1000InterfaceDripMsg.java TOSBaseCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

CC1000InterfaceDripMsg.java: $(LIB)/CC1000/CC1000Interface.h
	$(MIG) -java-classname=$(PACKAGE).CC1000InterfaceDripMsg $(TOSDIR)/../beta/SystemCore/CC1000/CC1000Interface.h CC1000InterfaceDripMsg -o $@

NamingMsg.java: $(LIB)/AM/AMNamingMsg.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(TOSDIR)/../beta/SystemCore/AM/AMNamingMsg.h NamingMsg -o $@

DripMsg.java: $(LIB)/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(TOSDIR)/../beta/SystemCore/Drip/Drip.h DripMsg -o $@

TOSBaseCmdMsg.java: $(LIB)/TOSBase/TOSBase.h
	$(MIG) -java-classname=$(PACKAGE).TOSBaseCmdMsg $(LIB)/TOSBase/TOSBase.h TOSBaseCmdMsg -o$@

cleanmig:
	rm -f $(MSGS)
