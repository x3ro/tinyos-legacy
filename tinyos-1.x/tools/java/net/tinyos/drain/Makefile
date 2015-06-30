TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drain
MIG = mig java
NCG = ncg java
LIB = $(TOSDIR)/lib

# List of message classes to build
MSGS = DrainMsg.java DrainBeaconMsg.java DrainGroupRegisterMsg.java DrainConsts.java
CONSTS = 
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig
PLATFORM = telosb
PLATFORM_LIBS = -I$(TOS)/lib/CC2420Radio

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DrainMsg.java: $(LIB)/Drain/Drain.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DrainMsg $(LIB)/Drain/Drain.h DrainMsg -o $@

DrainBeaconMsg.java: $(LIB)/Drain/Drain.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DrainBeaconMsg $(LIB)/Drain/Drain.h DrainBeaconMsg -o $@

DrainGroupRegisterMsg.java: $(LIB)/Drain/Drain.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DrainGroupRegisterMsg $(LIB)/Drain/Drain.h DrainGroupRegisterMsg -o $@

DrainConsts.java: $(LIB)/Drain/Drain.h
	$(NCG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DrainConsts -I$(LIB)/Drain $(LIB)/Drain/Drain.h Drain.h -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

