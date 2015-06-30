TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.eventlogger
MIG = mig java

# List of message classes to build
MSGS = DripMsg.java LogEntryMsg.java NamingMsg.java EventLoggerCmdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

DripMsg.java: $(TOSDIR)/../beta/SystemCore/Drip/Drip.h
	$(MIG) -java-classname=$(PACKAGE).DripMsg $(TOSDIR)/../beta/SystemCore/Drip/Drip.h DripMsg -o $@

LogEntryMsg.java: $(TOSDIR)/../beta/SystemCore/EventLogger/EventLogger.h
	$(MIG) -java-classname=$(PACKAGE).LogEntryMsg $(TOSDIR)/../beta/SystemCore/EventLogger/EventLogger.h LogEntryMsg -o $@

NamingMsg.java: $(TOSDIR)/../beta/SystemCore/AM/AMEnhanced.h
	$(MIG) -java-classname=$(PACKAGE).NamingMsg $(TOSDIR)/../beta/SystemCore/AM/AMNamingMsg.h NamingMsg -o $@

EventLoggerCmdMsg.java: $(TOSDIR)/../beta/SystemCore/EventLogger/EventLogger.h
	$(MIG) -java-classname=$(PACKAGE).EventLoggerCmdMsg $(TOSDIR)/../beta/SystemCore/EventLogger/EventLogger.h EventLoggerCmdMsg -o $@

cleanmig:
	rm -f $(MSGS)
