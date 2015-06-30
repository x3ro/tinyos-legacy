
TOS = $(shell ncc -print-tosdir)
MIG = mig java

# List of message classes to build
MSGS = MultihopMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(shell ncc -print-tosdir)/../tools/java
include $(ROOT)/Makefile.include

MultihopMsg.java:
	$(MIG) -java-classname=MultihopMsg $(TOS)/lib/MintRoute/MultiHop.h MultihopMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

