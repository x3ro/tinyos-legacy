TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.magtracking
MIG = mig java
JAVA = javac

# List of message classes to build
MSGS = RouteByAddress.java RouteByBroadcast.java RouteByLocation.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

RouteByAddress.java:
	$(MIG) -java-classname=$(PACKAGE).RouteByAddress ./Packets.h RouteByAddress >$@
	$(JAVAC) $@

RouteByBroadcast.java:
	$(MIG) -java-classname=$(PACKAGE).RouteByBroadcast ./Packets.h RouteByBroadcast >$@
	$(JAVAC) $@

RouteByLocation.java:
	$(MIG) -java-classname=$(PACKAGE).RouteByLocation ./Packets.h RouteByLocation >$@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

