TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.ranging
MIG = mig java
JAVA = javac

# List of message classes to build
#MSGS = TofChirpMsg.java TofRangingDataMsg.java TofChirpMsg.class TofRangingDataMsg.class
MSGS = TofChirpMsg.java TofRangingDataMsg.java TofChirpCommandMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

TofChirpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TofChirpMsg $(TOS)/lib/Ranging/TofRanging.h TofChirpMsg >$@
	$(JAVAC) $@

TofRangingDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TofRangingDataMsg $(TOS)/lib/Ranging/TofRanging.h TofRangingDataMsg >$@
	$(JAVAC) $@

TofChirpCommandMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TofChirpCommandMsg $(TOS)/lib/Ranging/TofRanging.h TofChirpCommandMsg >$@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

