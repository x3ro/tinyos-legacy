TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.localizationTest
MIG = mig
TOOL = java
JAVA = javac
SOURCE = ../../../../../localizationTest
INCLUDE_PATH = -I$(SOURCE)/. -I$(SOURCE)/build -I$(SOURCE)/../routing -I$(SOURCE)/../common -I$(SOURCE)/../magsensor -I$(SOURCE)/../localization -I$(SOURCE)/../neighborhood -I$(SOURCE)/../ptzcamera -I$(SOURCE)/../commandInterpreter -I$(SOURCE)/../TimedLeds -I$(SOURCE)/../Config -I$(SOURCE)/../TickSensor -I$(SOURCE)/../CameraPointer -I$(SOURCE)/../PhotoSensor -I$(SOURCE)/../ranging

# List of message classes to build
MSGS = LocationTuple.java RangingTuple.java AnchorTuple.java TupleRequestByBroadcast.java TupleRequestByAddress.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

LocationTuple.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).LocationTuple $(TOOL) $(SOURCE)/Packets.h LocationTuple >$@

RangingTuple.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).RangingTuple $(TOOL) $(SOURCE)/Packets.h RangingTuple >$@

AnchorTuple.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).AnchorTuple $(TOOL) $(SOURCE)/Packets.h AnchorTuple >$@

AnchorCorrectionTuple.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).AnchorCorrectionTupleTuple $(TOOL) $(SOURCE)/Packets.h AnchorCorrectionTuple >$@

TupleRequestByBroadcast.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).TupleRequestByBroadcast $(TOOL) $(SOURCE)/Packets.h TupleRequestByBroadcast >$@

TupleRequestByAddress.java:
	$(MIG) $(INCLUDE_PATH) -java-classname=$(PACKAGE).TupleRequestByAddress $(TOOL) $(SOURCE)/Packets.h TupleRequestByAddress >$@


cleanmig:
	rm -f $(MSGS)


