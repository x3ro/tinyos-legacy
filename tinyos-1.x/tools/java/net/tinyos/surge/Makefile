# Top-level Makefile for tools/java 

SUBDIRS = event util PacketAnalyzer Dialog

TOS = ${TOSDIR}/..
PACKAGE = net.tinyos.surge
MIG = mig java
#PCFLAGS = -target=pc

# List of message classes to build
MSGS = SurgeMsg.java SurgeCmdMsg.java BcastMsg.java MultihopMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

SURGE_MSG=$(TOS)/apps/Surge/Surge.h
SURGE_CMD_MSG=$(TOS)/apps/Surge/SurgeCmd.h
MULTIHOP_MSG=$(TOS)/tos/lib/Route/MultiHop.h
BCAST_MSG=$(TOS)/tos/lib/Broadcast/Bcast.h

ifeq ($(SURGE_PLATFORM),telos)
SURGE_MSG=$(TOS)/apps/SurgeTelos/Surge.h
SURGE_CMD_MSG=$(TOS)/apps/SurgeTelos/SurgeCmd.h
MULTIHOP_MSG=$(TOS)/tos/lib/MultiHopLQI/MultiHop.h
# BCAST_MSG remains the same
endif

SurgeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeMsg $(PCFLAGS) $(SURGE_MSG) SurgeMsg -o $@

SurgeCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeCmdMsg $(PCFLAGS) $(SURGE_CMD_MSG) SurgeCmdMsg -o $@

MultihopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MultihopMsg $(PCFLAGS) $(MULTIHOP_MSG) MultihopMsg -o $@

BcastMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BcastMsg $(PCFLAGS) $(BCAST_MSG) _BcastMsg -o $@

cleanmig:
	rm -f $(MSGS)

