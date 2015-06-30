PACKAGE = net.tinyos.multihop
OTHER_CLEAN = cleanmig
LIB=$(TOSDIR)/../beta/SystemCore/MultiHopRSSI

MIG = mig -I$(LIB) java
NCG = ncg -I$(LIB) java

MSGS = MultihopLayerMsg.java MultihopBeaconMsg.java TOSBaseCmdMsg.java
INITIAL_TARGETS = $(MSGS)

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

MultihopLayerMsg.java: $(LIB)/MultiHopLayer.h
	$(MIG) -java-classname=$(PACKAGE).MultihopLayerMsg $(LIB)/MultiHopLayer.h MultihopLayerMsg -o$@

MultihopBeaconMsg.java: $(LIB)/MultiHopLayer.h
	$(MIG) -java-classname=$(PACKAGE).MultihopBeaconMsg $(LIB)/MultiHopLayer.h MultihopBeaconMsg -o$@

TOSBaseCmdMsg.java: $(LIB)/../TOSBase/TOSBase.h
	$(MIG) -java-classname=$(PACKAGE).TOSBaseCmdMsg $(LIB)/../TOSBase/TOSBase.h TOSBaseCmdMsg -o$@

cleanmig:
	rm -f $(MSGS)
