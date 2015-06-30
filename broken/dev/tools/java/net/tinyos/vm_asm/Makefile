
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.vm_asm
MIG = mig java

# List of message classes to build
MSGS = BombillaErrorMsg.java BombillaCapsuleMsg.java BombillaDataMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

BombillaErrorMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BombillaErrorMsg $(TOS)/lib/BombillaMsgs.h BombillaErrorMsg >$@

BombillaCapsuleMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BombillaCapsuleMsg $(TOS)/lib/BombillaMsgs.h BombillaCapsuleMsg >$@

BombillaDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BombillaDataMsg $(TOS)/lib/BombillaMsgs.h BombillaPacketMsg >$@

cleanmig:
	rm -f $(MSGS)

