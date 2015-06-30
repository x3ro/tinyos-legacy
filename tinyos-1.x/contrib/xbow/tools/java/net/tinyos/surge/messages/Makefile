PACKAGE = net.tinyos.surge
MIG = mig java

MSGS = DebugPacket.java SurgeMsg.java MultihopMsg.java BcastMsg.java SurgeCmdMsg.java

CLEAN_MSGS = DebugPacket.java SurgeMsg.java MultihopMsg.java SurgeCmdMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

TOS = ../../../../../../../..

ROOT = ../../../../../../../../tools/java
include $(ROOT)/Makefile.include

MultihopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.MultihopMsg $(PCFLAGS) $(TOS)/tos/lib/Route/MultiHop.h MultihopMsg -o $@

DebugPacket.java:
	$(MIG) -java-classname=$(PACKAGE).messages.DebugPacket $(PCFLAGS) $(TOS)/contrib/xbow/tos/lib/ReliableRoute/MultiHop.h DebugPacket -o $@

SurgeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.SurgeMsg $(PCFLAGS) $(TOS)/contrib/xbow/apps/Surge/Surge.h SurgeMsg -o $@

SurgeDemoMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.SurgeDemoMsg $(PCFLAGS) $(TOS)/contrib/xbow/apps/Surge_Reliable/Surge.h SurgeDemoMsg -o $@

BcastMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.BcastMsg $(PCFLAGS) $(TOS)/tos/lib/Broadcast/Bcast.h _BcastMsg -o $@

SurgeCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).messages.SurgeCmdMsg $(PCFLAGS) $(TOS)/contrib/xbow/apps/Surge_Reliable/SurgeCmd.h SurgeCmdMsg -o $@

cleanmig:
	rm -f $(CLEAN_MSGS)

