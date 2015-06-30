TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.sentri
APP=$(TOSROOT)/contrib/GGB/apps/Sentri
MIG = mig java
NCG = ncg java
INCLUDES = -I$(TOS)/lib/CC2420Radio
PLATFORM = micaz

MSGS = CmdBcastMsg.java MultihopMsg.java CmdMsg.java ReplyMsg.java UARTMsg.java
CONSTS = SentriConsts.java

INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include


CmdBcastMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).CmdBcastMsg $(APP)/CmdBcast.h CmdBcastMsg -o $@

MultihopMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).MultihopMsg $(TOS)/lib/MintRoute/MultiHop.h MultihopMsg -o $@

CmdMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).CmdMsg $(APP)/CmdMsg.h CmdMsg -o $@

ReplyMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).ReplyMsg $(APP)/ReplyMsg.h ReplyMsg -o $@

UARTMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).UARTMsg $(APP)/ReplyMsg.h UARTMsg -o $@


SentriConsts.java: $(APP)/DataCollector.h $(APP)/CmdMsg.h $(APP)/ReplyMsg.h
	$(NCG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).SentriConsts -I$(APP) $(APP)/DataCollector.h $(APP)/CmdMsg.h $(APP)/ReplyMsg.h DataCollector.h CmdMsg.h ReplyMsg.h -o $@


cleanmig:
	rm -f $(MSGS) $(CONSTS)

