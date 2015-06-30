TOS = $(shell ncc -print-tosdir)
APP = /../contrib/ucb/apps/ChipconRSSI
PACKAGE = net.tinyos.chipconRSSI
MIG = mig java
JAVA = javac

# List of message classes to build
MSGS = ChirpMsg.java DataMsg.java DataOverviewMsg.java ChirpCommandMsg.java DataRequestMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

ChirpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ChirpMsg $(TOS)$(APP)/ChipconRSSI.h ChirpMsg >$@
	$(JAVAC) $@

DataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataMsg $(TOS)$(APP)/ChipconRSSI.h DataMsg >$@
	$(JAVAC) $@

DataOverviewMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataOverviewMsg $(TOS)$(APP)/ChipconRSSI.h DataOverviewMsg >$@
	$(JAVAC) $@

ChirpCommandMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ChirpCommandMsg $(TOS)$(APP)/ChipconRSSI.h ChirpCommandMsg >$@
	$(JAVAC) $@

DataRequestMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataRequestMsg $(TOS)$(APP)/ChipconRSSI.h DataRequestMsg >$@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

