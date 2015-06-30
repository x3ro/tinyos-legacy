TOS = $(shell ncc -print-tosdir)

PACKAGE = net.tinyos.surge
MIG = mig java -I$(TOS)/../contrib/eyes/platform/eyesIFX -I$(TOS)/../contrib/eyes/platform/eyesIFXv2 -I$(TOS)/platform/msp430 -I$(TOS)/../contrib/eyes/tos/lib/Broadcast -target=eyesIFXv2

# List of message classes to build
MSGS = SurgeMsg.java SurgeCmdMsg.java BcastMsg.java MultihopMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include

SURGE_MSG=$(TOS)/../contrib/eyes/apps/SurgeEyesIFX/Surge.h
#SURGE_MSG=$(TOS)/../apps/Surge/Surge.h
SURGE_CMD_MSG=$(TOS)/../contrib/eyes/apps/SurgeEyesIFX/SurgeCmd.h
#SURGE_CMD_MSG=$(TOS)/../apps/Surge/SurgeCmd.h
MULTIHOP_MSG=$(TOS)/../contrib/eyes/tos/lib/MultiHopRSSI/MultiHop.h
BCAST_MSG=$(TOS)/../contrib/eyes/tos/lib/Broadcast/Bcast.h

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

