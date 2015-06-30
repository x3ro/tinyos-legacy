
PACKAGE = com.moteiv.trawler
TOS=$(TOSDIR)/..
MOTEIV_DIR ?= ../../../../../
MIG = mig java -target=telos -I$(TOSDIR)/lib/CC2420Radio -I$(MOTEIV_DIR)/tos/lib/MultiHopLQI
MSGS = SurgeMsg.java SurgeCmdMsg.java BcastMsg.java MultihopMsg.java
JAVAC=javac -source 1.4
SURGE_MSG=$(TOS)/apps/SurgeTelos/Surge.h
SURGE_CMD_MSG=$(TOS)/apps/SurgeTelos/SurgeCmd.h
MULTIHOP_MSG=$(MOTEIV_DIR)/tos/lib/MultiHopLQI/MultiHop.h
DELTA_MSG=$(MOTEIV_DIR)/apps/Delta/Delta.h
BCAST_MSG=$(TOS)/tos/lib/Broadcast/Bcast.h

INCLUDES += -I$(MOTEIV_DIR)/tos/platform/tmote/util/uartdetect
INCLUDES += -I$(MOTEIV_DIR)/tos/lib/sp
INCLUDES += -I$(MOTEIV_DIR)/tos/lib/CC2420Radio
INCLUDES += -I$(TOSDIR)/lib/CC2420Radio

PCFLAGS += $(INCLUDES)

NCG = ncg java

MSGS = DeltaMsg.java MultiHopMsg.java UartDetectMsg.java UartDetectConsts.java

CLASSES = DeltaMsg.class \
	MultiHopMsg.class \
	UartDetectMsg.class \
	UartDetectConsts.class \
	LinkData.class \
	MoteInterface.class \
	NodeData.class \
	NodeTips.class \
	UartDetect.class \
	GraphIO.class \
	Trawler.class

JAVA_SRCS = DeltaMsg.java \
	MultiHopMsg.java \
	UartDetectMsg.java \
	UartDetectConsts.java \
	LinkData.java \
	MoteInterface.java \
	NodeData.java \
	NodeTips.java \
	UartDetect.java \
	GraphIO.java \
	Trawler.java

BASE_CLASS=net.tinyos.message.LinkedMessage
all: $(MSGS) $(CLASSES)

%.class: %.java
	$(JAVAC) -sourcepath ../../../ $(JAVA_SRCS)

UartDetectMsg.java:
	$(MIG) -java-classname=$(PACKAGE).UartDetectMsg $(PCFLAGS) $(MOTEIV_DIR)/tos/platform/tmote/util/uartdetect/UartDetectMsg.h UartDetectMsg -o $@

UartDetectConsts.java:
	$(NCG) -java-classname=$(PACKAGE).UartDetectConsts -target=telosb $(INCLUDES) $(MOTEIV_DIR)/tos/platform/tmote/util/uartdetect/UartDetectMsg.h UartDetectMsg.h UartDetectConsts -o $@

SurgeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeMsg  -java-extends=$(BASE_CLASS) $(PCFLAGS) $(SURGE_MSG) SurgeMsg -o $@

DeltaMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DeltaMsg  -java-extends=$(BASE_CLASS) $(PCFLAGS) $(DELTA_MSG) DeltaMsg -o $@

SurgeCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SurgeCmdMsg  -java-extends=$(BASE_CLASS)  $(PCFLAGS) $(SURGE_CMD_MSG) SurgeCmdMsg -o $@

MultiHopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MultiHopMsg  -java-extends=$(BASE_CLASS)  $(PCFLAGS) $(MULTIHOP_MSG) MultihopMsg -o $@

BcastMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BcastMsg  -java-extends=${BASE_CLASS) $(PCFLAGS) $(BCAST_MSG) _BcastMsg -o $@

cleanmig:
	rm -f $(MSGS)

cleanclass:
	rm -f *.class

clean: cleanmig cleanclass
