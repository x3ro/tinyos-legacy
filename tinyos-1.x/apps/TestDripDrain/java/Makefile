TOS = $(shell ncc -print-tosdir)
PACKAGE = 
MIG = mig java
NCG = ncg java

MSGS = DripDrainPingMsg.java 
CONSTS = DripDrainPingConsts.java
INITIAL_TARGETS =  $(CONSTS) $(MSGS)
OTHER_CLEAN = cleanmig
PLATFORM = telosb
PLATFORM_LIBS = -I$(TOS)/lib/CC2420Radio

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripDrainPingMsg.java: ../DripDrainPing.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=DripDrainPingMsg ../DripDrainPing.h DripDrainPingMsg -o $@

DripDrainPingConsts.java: ../DripDrainPing.h
	$(NCG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=DripDrainPingConsts ../DripDrainPing.h DripDrainPing.h -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties
