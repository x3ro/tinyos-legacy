TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.timesync
APP=$(TOS)/../apps/TestTiming
MIG = mig java

# List of message classes to build
MSGS = TimeResp.java 
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

TimeResp.java:
	$(MIG) -java-classname=$(PACKAGE).TimeResp $(APP)/SendTime.h TimeResp >$@
SimpleCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SimpleCmdMsg $(TOS)/lib/SimpleCmdMsg.h SimpleCmdMsg >$@

cleanmig:
	rm -f $(MSGS)
