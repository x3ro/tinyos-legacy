TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drain
MIG = mig java
NCG = ncg java
BETA = $(TOSDIR)/../beta
LIB = $(TOSDIR)/../contrib/nucleus/tos/lib

# List of message classes to build
MSGS = DrainMsg.java DrainBeaconMsg.java DrainGroupRegisterMsg.java DrainConsts.java DrainTestMsg.java
CONSTS = 
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DrainMsg.java: $(BETA)/Drain/Drain.h
	$(MIG) -java-classname=$(PACKAGE).DrainMsg $(BETA)/Drain/Drain.h DrainMsg -o $@

DrainBeaconMsg.java: $(BETA)/Drain/Drain.h
	$(MIG) -java-classname=$(PACKAGE).DrainBeaconMsg $(BETA)/Drain/Drain.h DrainBeaconMsg -o $@

DrainGroupRegisterMsg.java: $(BETA)/Drain/Drain.h
	$(MIG) -java-classname=$(PACKAGE).DrainGroupRegisterMsg $(BETA)/Drain/Drain.h DrainGroupRegisterMsg -o $@

DrainTestMsg.java: $(BETA)/Drain/DrainTest.h
	$(MIG) -java-classname=$(PACKAGE).DrainTestMsg $(BETA)/Drain/DrainTest.h DrainTestMsg -o $@

DrainConsts.java: $(BETA)/Drain/Drain.h
	$(NCG) -java-classname=$(PACKAGE).DrainConsts -I$(BETA)/Drain $(BETA)/Drain/Drain.h Drain.h -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

