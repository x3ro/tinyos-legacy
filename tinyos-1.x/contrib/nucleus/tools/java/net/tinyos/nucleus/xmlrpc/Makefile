TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.drip
MIG = mig java
NCG = ncg java
LIB =

# List of message classes to build
MSGS = 
CONSTS = 
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig
PLATFORM = pc

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

