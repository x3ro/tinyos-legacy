MCCORD_ROOTDIR=..

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.mccord
JAVA_SRC_DIR = java/net/tinyos/mccord

MIG = mig java
NCG = ncg java

MSGS = $(JAVA_SRC_DIR)/UARTMetaMsg.java \
       $(JAVA_SRC_DIR)/UARTDataMsg.java \
       $(JAVA_SRC_DIR)/Consts.java 

PLATFORM=telosb

INCLUDES=-I$(MCCORD_ROOTDIR)/tos/lib/McCORD \
         -I$(MCCORD_ROOTDIR)/tos/interfaces 

ifeq ($(PLATFORM),telosb)
    INCLUDES+=-I$(MCCORD_ROOTDIR)/tos/platform/telosb -I$(TOS)/lib/CC2420Radio
else
    echo "Platform not supported."
endif

all: $(MSGS)
	cd $(JAVA_SRC_DIR); javac *.java

$(JAVA_SRC_DIR)/UARTMetaMsg.java:
	$(MIG) -java-classname=$(PACKAGE).UARTMetaMsg -target=$(PLATFORM) $(INCLUDES) $(MCCORD_ROOTDIR)/tos/lib/McCORD/McCORD.h UARTMetaMsg -o $@

$(JAVA_SRC_DIR)/UARTDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).UARTDataMsg -target=$(PLATFORM) $(INCLUDES) $(MCCORD_ROOTDIR)/tos/lib/McCORD/McCORD.h UARTDataMsg -o $@

$(JAVA_SRC_DIR)/Consts.java:
	$(NCG) -java-classname=$(PACKAGE).Consts -target=$(PLATFORM) $(INCLUDES) $(MCCORD_ROOTDIR)/tos/lib/McCORD/McCORDC.nc McCORD.h Consts -o $@

clean:
	rm -f $(MSGS)
	rm -f $(JAVA_SRC_DIR)/*.class

