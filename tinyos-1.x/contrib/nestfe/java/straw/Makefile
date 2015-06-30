TOS = $(shell ncc -print-tosdir)
PACKAGE = straw
LIB=$(TOS)/../contrib/nestfe/nesc/lib/Straw
MIG = mig java
PLATFORM = telosb
INCLUDES = -I$(TOSDIR)/lib/CC2420Radio

# List of message classes to build
MSGS = StrawBcastMsg.java StrawCmdMsg.java StrawReplyMsg.java StrawUARTMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../../tools/java
include $(ROOT)/Makefile.include

StrawBcastMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawBcastMsg $(LIB)/StrawBcast.h StrawBcastMsg -o $@

StrawCmdMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawCmdMsg $(LIB)/Straw.h StrawCmdMsg -o $@

StrawReplyMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawReplyMsg $(LIB)/Straw.h StrawReplyMsg -o $@

StrawUARTMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawUARTMsg $(LIB)/Straw.h StrawUARTMsg -o $@

cleanmig:
	rm -f $(MSGS)
