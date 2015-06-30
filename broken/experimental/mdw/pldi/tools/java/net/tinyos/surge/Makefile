# Top-level Makefile for tools/java 

SUBDIRS = event util PacketAnalyzer Dialog

TOS = ../../../../..
PACKAGE = net.tinyos.surge
MIG = mig java

# List of message classes to build
MSGS = MultihopMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

MultihopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MultihopMsg $(TOS)/multihop/Multihop.h MultihopMsg >$@

cleanmig:
	rm -f $(MSGS)

