# Top-level Makefile for tools/java 

SUBDIRS = event util PacketAnalyzer Dialog

TOS = ../../../../..
#TOS = /home/culler/tinyos-1.x/broken/experimental/dec/surge3
PACKAGE = net.tinyos.surge
MIG = mig java
#PCFLAGS = -target=pc

# List of message classes to build
MSGS = SurgeMsg.java bcastMsg.java MultihopMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

SurgeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeMsg $(PCFLAGS) $(TOS)/apps/Surge/Surge.h SurgeMsg >$@

MultihopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MultihopMsg $(PCFLAGS) $(TOS)/tos/lib/Route/MultiHop.h MultihopMsg >$@

bcastMsg.java:
	$(MIG) -java-classname=$(PACKAGE).bcastMsg $(PCFLAGS) $(TOS)/apps/Surge/bcast.h bcastMsg >$@

cleanmig:
	rm -f $(MSGS)

