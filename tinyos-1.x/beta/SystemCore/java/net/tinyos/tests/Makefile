PACKAGE = net.tinyos.tests
OTHER_CLEAN = cleanmig
LIB = $(TOSDIR)/../beta/SystemCore

MIG = mig java
NCG = ncg java

MSGS = DripMsg.java TestDripMsg.java
INITIAL_TARGETS = $(MSGS)

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripMsg.java: $(LIB)/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(LIB)/Drip/Drip.h DripMsg -o $@

TestDripMsg.java: $(LIB)/tests/TestDrip/TestDrip.h
	$(MIG) -java-classname=$(PACKAGE).TestDripMsg $(LIB)/tests/TestDrip/TestDrip.h TestDripMsg -o $@


cleanmig:
	rm -f $(MSGS)
