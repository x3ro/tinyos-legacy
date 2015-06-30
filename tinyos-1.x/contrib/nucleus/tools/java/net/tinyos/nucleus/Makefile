TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.nucleus
MIG = mig java
NCG = ncg java
BETA = $(TOSDIR)/../beta
LIB = $(TOSDIR)/../contrib/nucleus/tos/lib

# List of message classes to build
MSGS = DestMsg.java MgmtQueryMsg.java MgmtQueryResponseMsg.java LogEntryMsg.java GrouperCmdMsg.java RemoteSetMsg.java
CONSTS = MgmtQueryConsts.java GrouperConsts.java
INITIAL_TARGETS = $(MSGS) $(CONSTS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DestMsg.java: $(LIB)/Nucleus/DestMsg.h
	$(MIG) -java-classname=$(PACKAGE).DestMsg $(LIB)/Nucleus/DestMsg.h DestMsg -o $@

MgmtQueryMsg.java: $(LIB)/Nucleus/MgmtQuery.h
	$(MIG) -java-classname=$(PACKAGE).MgmtQueryMsg $(LIB)/Nucleus/MgmtQuery.h MgmtQueryMsg -o $@

RemoteSetMsg.java: $(LIB)/Nucleus/RemoteSet.h
	$(MIG) -java-classname=$(PACKAGE).RemoteSetMsg $(LIB)/Nucleus/RemoteSet.h RemoteSetMsg -o $@

MgmtQueryResponseMsg.java: $(LIB)/Nucleus/MgmtQuery.h
	$(MIG) -java-classname=$(PACKAGE).MgmtQueryResponseMsg $(LIB)/Nucleus/MgmtQuery.h MgmtQueryResponseMsg -o $@

MgmtQueryConsts.java: $(LIB)/Nucleus/MgmtQuery.h
	$(NCG) -java-classname=$(PACKAGE).MgmtQueryConsts -I$(LIB)/Nucleus $(LIB)/Nucleus/MgmtQuery.h MgmtQuery.h -o $@

LogEntryMsg.java: $(LIB)/Nucleus/EventLogger.h
	$(MIG) -java-classname=$(PACKAGE).LogEntryMsg $(LIB)/Nucleus/EventLogger.h LogEntryMsg -o $@

GrouperCmdMsg.java: $(LIB)/Nucleus/Grouper.h
	$(MIG) -java-classname=$(PACKAGE).GrouperCmdMsg $(LIB)/Nucleus/Grouper.h GrouperCmdMsg -o $@

GrouperConsts.java: $(LIB)/Nucleus/Grouper.h
	$(NCG) -java-classname=$(PACKAGE).GrouperConsts -I$(LIB)/Nucleus $(LIB)/Nucleus/Grouper.h Grouper.h -o $@

cleanmig:
	rm -f $(MSGS) $(CONSTS) platforms.properties

