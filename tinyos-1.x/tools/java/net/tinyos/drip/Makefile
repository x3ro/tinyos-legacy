TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drip
MIG = mig java
NCG = ncg java
LIB = $(TOSDIR)/lib/Drip

# List of message classes to build
MSGS = DripMsg.java AddressMsg.java TestDripMsg.java
CONSTS = DripConsts.java
INITIAL_TARGETS = $(CONSTS) $(MSGS)
OTHER_CLEAN = cleanmig
PLATFORM = telosb
PLATFORM_LIBS = -I$(TOS)/lib/CC2420Radio

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripMsg.java: $(LIB)/Drip.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DripMsg $(LIB)/Drip.h DripMsg -o $@

AddressMsg.java: $(LIB)/DripSend.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).AddressMsg $(LIB)/DripSend.h AddressMsg -o $@

DripConsts.java: $(LIB)/Drip.h
	$(NCG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).DripConsts -I$(LIB) $(LIB)/Drip.h Drip.h -o $@

TestDripMsg.java: $(TOSDIR)/../apps/TestDrip/TestDrip.h
	$(MIG) -target=$(PLATFORM) $(PLATFORM_LIBS) -java-classname=$(PACKAGE).TestDripMsg $(TOSDIR)/../apps/TestDrip/TestDrip.h TestDripMsg -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

