TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.hello
MIG = mig java
LIB = $(TOSDIR)/../beta/SystemCore

# List of message classes to build
MSGS = HelloMsg.java HelloReqMsg.java HelloCmdMsg.java NamingMsg.java TOSBaseCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

HelloMsg.java: $(LIB)/Hello/Hello.h
	$(MIG) -java-classname=$(PACKAGE).HelloMsg $(LIB)/Hello/Hello.h HelloMsg -o $@

HelloReqMsg.java: $(LIB)/Hello/Hello.h
	$(MIG) -java-classname=$(PACKAGE).HelloReqMsg $(LIB)/Hello/Hello.h HelloReqMsg -o $@

HelloCmdMsg.java: $(LIB)/Hello/Hello.h
	$(MIG) -java-classname=$(PACKAGE).HelloCmdMsg $(LIB)/Hello/Hello.h HelloCmdMsg -o $@

NamingMsg.java: $(LIB)/AM/AMEnhanced.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(LIB)/AM/AMNamingMsg.h NamingMsg -o $@

TOSBaseCmdMsg.java: $(LIB)/TOSBase/TOSBase.h
	$(MIG) -java-classname=$(PACKAGE).TOSBaseCmdMsg $(LIB)/TOSBase/TOSBase.h TOSBaseCmdMsg -o$@

cleanmig:
	rm -f $(MSGS)
