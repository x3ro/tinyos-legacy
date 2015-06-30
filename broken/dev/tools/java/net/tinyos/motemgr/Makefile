TOS=$(shell ncc -print-tosdir)
APPS=$(TOS)/../apps

PACKAGE = net.tinyos.motemgr
APP=$(APPS)/MoteAgent

MIG = mig java

MSGS = MoteIdRspMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include
 
all: $(MSGS)
	javac *.java

MoteIdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MoteIdMsg $(APP)/MoteIdRspMsg.h MoteIdRsp >$@

MoteIdRspMsg.java:
	$(MIG) -java-classname=$(PACKAGE).MoteIdRspMsg $(APP)/MoteIdRspMsg.h MoteIdRspMsg >$@

#clean:
#	rm $(MSGS) *.class
