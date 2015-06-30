PACKAGE = tools
APP=..

MIG = mig -I$(APP) java

MSGS = FSOpMsg.java FSReplyMsg.java

all: $(MSGS)

FSOpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FSOpMsg $(APP)/Remote.nc FSOpMsg -o$@

FSReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).FSReplyMsg $(APP)/Remote.nc FSReplyMsg -o$@

cleanmig:
	rm -f $(MSGS)

