TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.pingpong
APP=$(TOS)/../contrib/nestfe/nesc/apps/PingPong
MIG = mig java
NCG = ncg java
PLATFORM = telosb
INCLUDES = -I$(TOS)/lib/CC2420Radio

MSGS = PpCmdMsg.java PpReplyMsg.java
CONSTS = PpConsts.java

INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include


PpCmdMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).PpCmdMsg $(APP)/PingPong.h PpCmdMsg -o $@

PpReplyMsg.java:
	$(MIG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).PpReplyMsg $(APP)/PingPong.h PpReplyMsg -o $@


PpConsts.java: $(APP)/PingPong.h
	$(NCG) -target=$(PLATFORM) $(INCLUDES) -java-classname=$(PACKAGE).PpConsts -I$(APP) $(APP)/PingPong.h PingPong.h -o $@


cleanmig:
	rm -f $(MSGS) $(CONSTS)
