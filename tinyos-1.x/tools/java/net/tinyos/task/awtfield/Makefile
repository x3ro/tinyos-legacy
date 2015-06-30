
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.task.awtfield
APP = $(TOS)/../apps/TASKApp
MIG = mig java

# List of message classes to build
MSGS = FieldMsg.java FieldReplyMsg.java WakeupMsg.java PingReplyMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

WakeupMsg.java:
	$(MIG) -java-classname=$(PACKAGE).WakeupMsg $(APP)/Field.h WakeupMsg -o $@
	$(JAVAC) $@

FieldMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FieldMsg $(APP)/Field.h FieldMsg -o $@
	$(JAVAC) $@

FieldReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FieldReplyMsg $(APP)/Field.h FieldReplyMsg -o $@
	$(JAVAC) $@

PingReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).PingReplyMsg $(APP)/PingReplyMsg.h PingReplyMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

