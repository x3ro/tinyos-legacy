TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.powermgmt
MIG = mig java	
LIB = $(TOSDIR)/../beta/SystemCore

# List of message classes to build
MSGS = DripMsg.java NamingMsg.java PowerMgmtCmdMsg.java TOSBaseCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

PowerMgmtCmdMsg.java: $(LIB)/PowerMgmt/PowerMgmt.h
	$(MIG) -java-classname=$(PACKAGE).PowerMgmtCmdMsg $(LIB)/PowerMgmt/PowerMgmt.h PowerMgmtCmdMsg -o $@

NamingMsg.java: $(LIB)/AM/AMEnhanced.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(LIB)/AM/AMNamingMsg.h NamingMsg -o $@

DripMsg.java: $(LIB)/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(LIB)/Drip/Drip.h DripMsg -o $@

TOSBaseCmdMsg.java: $(LIB)/TOSBase/TOSBase.h
	$(MIG) -java-classname=$(PACKAGE).TOSBaseCmdMsg $(LIB)/TOSBase/TOSBase.h TOSBaseCmdMsg -o$@

cleanmig:
	rm -f $(MSGS)
