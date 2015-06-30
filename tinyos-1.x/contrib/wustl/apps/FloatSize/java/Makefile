TOS = $(shell ncc -print-tosdir)

# List of message classes to build
MSGS = FloatMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN =

MIG=mig java
ROOT = $(TOS)/../tools/java

include $(ROOT)/Makefile.include
NCG = ncg java

BINCLUDES=-I../

FloatMsg.java:
	$(MIG) -java-classname=FloatMsg ../FloatMsg.h FloatMsg -o $@

mig: $(MSGS)

cleanmig:
	rm -f $(MSGS)
