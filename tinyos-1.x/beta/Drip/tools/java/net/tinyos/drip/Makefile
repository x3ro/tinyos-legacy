TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drip
MIG = mig java
NCG = ncg java
LIB = $(TOSDIR)/../beta/Drip

# List of message classes to build
MSGS = DripMsg.java AddressMsg.java TestDripMsg.java
CONSTS = DripConsts.java
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig
PLATFORM = pc

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripMsg.java: $(LIB)/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(LIB)/Drip.h DripMsg -o $@

AddressMsg.java: $(LIB)/DripSend.h
	$(MIG) -java-classname=$(PACKAGE).AddressMsg $(LIB)/DripSend.h AddressMsg -o $@

DripConsts.java: $(LIB)/Drip.h
	$(NCG) -java-classname=$(PACKAGE).DripConsts -I$(LIB) $(LIB)/Drip.h Drip.h -o $@

TestDripMsg.java: $(LIB)/TestDrip/TestDrip.h
	$(MIG) -java-classname=$(PACKAGE).TestDripMsg $(LIB)/TestDrip/TestDrip.h TestDripMsg -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

