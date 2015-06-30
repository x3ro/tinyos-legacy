TOS=$(shell ncc -print-tosdir)
APPS=$(TOS)/../apps
PACKAGE = net.tinyos.ident
APP=$(APPS)/Ident
MIG = mig -I$(APP) -I%T/lib/Util java

MSGS = IdentMsg.java SetIdMsg.java ClearIdMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

IdentMsg.java:
	$(MIG) -java-classname=$(PACKAGE).IdentMsg $(APP)/App.nc IdentMsg -o$@

SetIdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SetIdMsg $(APP)/App.nc SetIdMsg -o$@

ClearIdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ClearIdMsg $(APP)/App.nc ClearIdMsg -o$@

cleanmig:
	rm -f $(MSGS)
