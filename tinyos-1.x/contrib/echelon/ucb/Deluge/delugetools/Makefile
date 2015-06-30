PACKAGE = net.tinyos.deluge
OTHER_CLEAN = cleanmig
LIB=$(TOSDIR)/../beta/Deluge/Deluge

MIG = mig -I$(LIB) java
NCG = ncg -I$(LIB) java

MSGS = DelugeAdvMsg.java DelugeReqUpdMetadataMsg.java DelugeUpdMetadataMsg.java DelugeReqMsg.java DelugeDataMsg.java DelugeDurationMsg.java
INITIAL_TARGETS = $(MSGS)

ROOT = ../../..
include $(ROOT)/Makefile.include

DelugeAdvMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeAdvMsg $(LIB)/DelugeC.nc DelugeAdvMsg -o$@

DelugeReqUpdMetadataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeReqUpdMetadataMsg $(LIB)/DelugeC.nc DelugeReqUpdMetadataMsg -o$@

DelugeUpdMetadataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeUpdMetadataMsg $(LIB)/DelugeC.nc DelugeUpdMetadataMsg -o$@

DelugeReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeReqMsg $(LIB)/DelugeC.nc DelugeReqMsg -o$@

DelugeDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeDataMsg $(LIB)/DelugeC.nc DelugeDataMsg -o$@

DelugeDurationMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeDurationMsg $(LIB)/DelugeC.nc DelugeDurationMsg -o$@

cleanmig:
	rm -f $(MSGS)
