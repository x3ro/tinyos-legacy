TOS = $(shell ncc -print-tosdir)
PACKAGE = test_trio
MIG = mig java

# List of message classes to build
MSGS = TestTrioMsg.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../../tools/java
include $(ROOT)/Makefile.include

TESTTRIOMSG=$(TOS)/../contrib/nestfe/nesc/apps/TestTrioApps/TestTrioMsg.h

TestTrioMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TestTrioMsg $(TESTTRIOMSG) TestTrioMsg -o >$@ 
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS) *class *~

