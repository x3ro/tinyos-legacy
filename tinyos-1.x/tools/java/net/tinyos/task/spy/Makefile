
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.task.spy
APP = $(TOS)/../apps/TASKApp
MIG = mig java -I%T/lib/Util -I%T/lib/Attributes -I%T/lib/Commands -I%T/lib/TinyDB -I%T/lib/MintRoute -I%T/lib/Queue  -I%T/lib/FS -I%T/lib/TinyDB/Aggregates -board=micasb -I$(APP)

# List of message classes to build
MSGS = MultihopMsg.java QueryResult.java QueryMessage.java RoutePacket.java QueryRequestMessage.java CommandMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

MultihopMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MultihopMsg mhop.h MultihopMsg -o $@
	$(JAVAC) $@

QueryResult.java:
	$(MIG) -java-classname=$(PACKAGE).QueryResult $(APP)/TASKApp.nc QueryResult -o $@
	$(JAVAC) $@

QueryMessage.java:
	$(MIG) -java-classname=$(PACKAGE).QueryMessage $(APP)/TASKApp.nc QueryMessage -o $@
	$(JAVAC) $@

RoutePacket.java:
	$(MIG) -java-classname=$(PACKAGE).RoutePacket mhop.h RoutePacket -o $@
	$(JAVAC) $@

QueryRequestMessage.java:
	$(MIG) -java-classname=$(PACKAGE).QueryRequestMessage $(APP)/TASKApp.nc QueryRequestMessage -o $@
	$(JAVAC) $@

CommandMsg.java:
	$(MIG) -java-classname=$(PACKAGE).CommandMsg $(APP)/TASKApp.nc CommandMsg -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

