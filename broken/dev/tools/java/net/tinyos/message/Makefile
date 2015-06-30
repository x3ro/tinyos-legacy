
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

# List of message classes to build
MSGS = TOSMsg.java
INITIAL_TARGETS = $(MSGS) ../oscope/OscopeMsg.java 
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

../oscope/OscopeMsg.java:
	cd ../oscope
	make -C ../oscope -f Makefile

TOSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TOSMsg $(TOS)/system/AM.h TOS_Msg >$@

cleanmig:
	rm -f $(MSGS)

