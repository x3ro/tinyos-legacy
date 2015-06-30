#mig java -java-classname=net.tinyos.dim.ConsoleCmd /local/xinl/broken/experimental/dim/tos/lib/ConsoleCmd.h ConsoleCmd > ConsoleCmd.java
#TOS = $(shell ncc -print-tosdir)
TOS = /local/dim/broken/experimental/dim/tos
PACKAGE = net.tinyos.dim
MIG = mig java
JAVAC = javac

# List of message classes to build
MSGS = ConsoleQueryMsg.java ConsoleReplyMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

#ROOT = ../../..
#include $(ROOT)/Makefile.include
all: $(MSGS)

ConsoleQueryMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleQueryMsg -target=pc $(TOS)/lib/ConsoleCmd.h ConsoleQueryMsg >$@
	$(JAVAC) $@
ConsoleReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleReplyMsg -target=pc $(TOS)/lib/ConsoleCmd.h ConsoleReplyMsg >$@
	$(JAVAC) $@
BeaconMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BeaconMsg -target=pc $(TOS)/lib/ConsoleCmd.h BeaconMsg >$@
	$(JAVAC) $@
cleanmig:
	rm -f $(MSGS)
