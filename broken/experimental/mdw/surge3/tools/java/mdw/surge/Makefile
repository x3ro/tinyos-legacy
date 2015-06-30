# Top-level Makefile for tools/java 

SUBDIRS = event util PacketAnalyzer Dialog

TOS = ../../../..
PACKAGE = mdw.surge
MIG = mig java
#PCFLAGS = -target=pc

# List of message classes to build
MSGS = SurgeMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../..
include $(ROOT)/Makefile.include

SurgeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeMsg $(PCFLAGS) $(TOS)/apps/Surge/Surge.h SurgeMsg >$@

cleanmig:
	rm -f $(MSGS)

