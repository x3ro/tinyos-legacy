TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.magtracking
MIG = mig java
JAVA = javac

# List of message classes to build
MSGS = RouteToLandmark.java RouteFromLandmarkToPursuer.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

$(MSGS) : %.java : Packets.h
	$(MIG) -java-classname=$(PACKAGE).$* ./Packets.h $* >$@

#RouteByBroadcast.java:
#	$(MIG) -java-classname=$(PACKAGE).RouteByBroadcast ./Packets.h RouteByBroadcast >$@

#RouteByLocation.java:
#	$(MIG) -java-classname=$(PACKAGE).RouteByLocation ./Packets.h RouteByLocation >$@

cleanmig:
	rm -f $(MSGS)

