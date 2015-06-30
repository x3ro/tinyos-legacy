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
	$(MIG) -java-classname=$(PACKAGE).IdentMsg $(APP)/SocialM.nc IdentMsg -o$@

RegisterMsg.java:
	$(MIG) -java-classname=$(PACKAGE).RegisterMsg $(APP)/SocialM.nc RegisterMsg -o$@

ReqDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ReqDataMsg $(APP)/SocialM.nc ReqDataMsg -o$@

DataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataMsg $(APP)/SocialM.nc DataMsg -o$@

SocialPacket.java:
	$(MIG) -java-classname=$(PACKAGE).SocialPacket $(APP)/SocialM.nc SocialPacket -o$@

cleanmig:
	rm -f $(MSGS)

