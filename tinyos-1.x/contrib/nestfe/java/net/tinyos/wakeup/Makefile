TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.wakeup
MIG = mig java
NCG = ncg java
LIB = $(TOSDIR)/../contrib/nestfe/nesc/apps/GoldenImage

# List of message classes to build
MSGS = WakeupMsg.java
CONSTS = WakeupConsts.java
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig
PLATFORM = pc

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

WakeupMsg.java: $(LIB)/WakeupHeader.h
	$(MIG) -java-classname=$(PACKAGE).WakeupMsg $(LIB)/WakeupHeader.h WakeupMsg -o $@

WakeupConsts.java: $(LIB)/WakeupHeader.h
	$(NCG) $(INCLUDES) -java-classname=$(PACKAGE).WakeupConsts -I$(LIB) $(LIB)/WakeupHeader.h WakeupHeader.h -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.propertiest

