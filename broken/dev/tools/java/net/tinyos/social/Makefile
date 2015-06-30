TOS=$(shell ncc -print-tosdir)
APPS=$(TOS)/../apps

PACKAGE = net.tinyos.social
APP=$(APPS)/Social

MIG = mig -I$(APP) java

MSGS = IdentMsg.java RegisterMsg.java ReqDataMsg.java DataMsg.java SocialPacket.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

IdentMsg.java:
	$(MIG) -java-classname=$(PACKAGE).IdentMsg $(APP)/SocialM.td IdentMsg -o$@

RegisterMsg.java:
	$(MIG) -java-classname=$(PACKAGE).RegisterMsg $(APP)/SocialM.td RegisterMsg -o$@

ReqDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ReqDataMsg $(APP)/SocialM.td ReqDataMsg -o$@

DataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataMsg $(APP)/SocialM.td DataMsg -o$@

SocialPacket.java:
	$(MIG) -java-classname=$(PACKAGE).SocialPacket $(APP)/SocialM.td SocialPacket -o$@

cleanmig:
	rm -f $(MSGS)

