##########Generic Stuff##########
ifndef NESTFEDIR
NESTFEDIR := $(shell ncc -print-tosdir)/../contrib/nestfe
endif
ifndef DRAINDIR
DRAINDIR := $(shell ncc -print-tosdir)/../beta/Drain
endif

ROOT := $(shell ncc -print-tosdir)/../tools/java
MIG = mig java
NCG = ncg java
#################################


PACKAGE = net.tinyos.drain_msgs.DetectionEvent
DETECTIONEVENTDIR=$(NESTFEDIR)/nesc/lib/detectionevent
APPCOMPILEDIR=$(NESTFEDIR)/nesc/apps/TestDetectionEvent


## Flags for MIG and NCG
MIG_NCG_FLAGS = \
-target=telosb \
-board=trio \
-I$(APPCOMPILEDIR) \
-I$(DRAINDIR) \
-I$(DETECTIONEVENTDIR) \
-I%T/lib/CC2420Radio
# Not sure if using proper directory for CC2420Const.h
# (should we use the version in tinyos-2.x instead?)

# LIST of message classes to build
MSGS = DetectionEventMsg.java DetectionEventConst.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig


include $(ROOT)/Makefile.include

DetectionEventMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).DetectionEventMsg DetectionEventMsg.h DetectionEventMsg_MIG -o $@
	$(JAVAC) $@

#Only works if use the M file as the top level file
#So created a Dummy top level file so we avoid registry stuff not being recognized by MIG
DetectionEventConst.java:
	$(NCG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).DetectionEventConst DummyM.nc DetectionEvent.h Drain.h -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

