TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.straw
LIB=$(TOS)/../contrib/nestfe/nesc/lib/Straw
MIG = mig java
NCG = ncg java
PLATFORM = telosb
INCLUDES = -I$(TOS)/lib/CC2420Radio

# List of message classes to build
MSGS = StrawGrpMsg.java StrawCmdMsg.java StrawReplyMsg.java StrawUARTMsg.java
CONSTS = StrawConsts.java

INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include

StrawGrpMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawGrpMsg $(LIB)/Straw.h StrawGrpMsg -o $@

StrawCmdMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawCmdMsg $(LIB)/Straw.h StrawCmdMsg -o $@

StrawReplyMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawReplyMsg $(LIB)/Straw.h StrawReplyMsg -o $@

StrawUARTMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawUARTMsg $(LIB)/Straw.h StrawUARTMsg -o $@


StrawConsts.java: $(LIB)/Straw.h
	$(NCG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).StrawConsts -I$(LIB) $(LIB)/Straw.h Straw.h -o $@


cleanmig:
	rm -f $(MSGS) $(CONSTS)
