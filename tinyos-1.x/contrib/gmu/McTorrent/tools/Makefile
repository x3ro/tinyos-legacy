MCTORRENT_ROOTDIR=..

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.mctorrent
JAVA_SRC_DIR = java/net/tinyos/mctorrent

MIG = mig java
NCG = ncg java

MSGS = $(JAVA_SRC_DIR)/AdvMsg.java \
       $(JAVA_SRC_DIR)/ReqMsg.java \
       $(JAVA_SRC_DIR)/DataMsg.java \
       $(JAVA_SRC_DIR)/ChnMsg.java \
       $(JAVA_SRC_DIR)/Consts.java 

PLATFORM?= mica2

INCLUDES=-I$(MCTORRENT_ROOTDIR)/tos/lib/McTorrent \
         -I$(MCTORRENT_ROOTDIR)/tos/interfaces 

ifeq ($(PLATFORM),mica2)
    INCLUDES+=-I$(MCTORRENT_ROOTDIR)/tos/platform/mica2 -I$(TOS)/lib/CC1000Radio
else
    ifeq ($(PLATFORM),telosb)
        INCLUDES+=-I$(MCTORRENT_ROOTDIR)/tos/platform/telosb -I$(TOS)/lib/CC2420Radio
    else
        echo "Platform not supported."
    endif
endif

all: $(MSGS)
	cd $(JAVA_SRC_DIR); javac *.java

$(JAVA_SRC_DIR)/AdvMsg.java:
	$(MIG) -java-classname=$(PACKAGE).AdvMsg -target=$(PLATFORM) $(INCLUDES) $(MCTORRENT_ROOTDIR)/tos/lib/McTorrent/Msg.h AdvMsg -o $@

$(JAVA_SRC_DIR)/ReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ReqMsg -target=$(PLATFORM) $(INCLUDES) $(MCTORRENT_ROOTDIR)/tos/lib/McTorrent/Msg.h ReqMsg -o $@

$(JAVA_SRC_DIR)/DataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DataMsg -target=$(PLATFORM) $(INCLUDES) $(MCTORRENT_ROOTDIR)/tos/lib/McTorrent/Msg.h DataMsg -o $@

$(JAVA_SRC_DIR)/ChnMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ChnMsg -target=$(PLATFORM) $(INCLUDES) $(MCTORRENT_ROOTDIR)/tos/lib/McTorrent/Msg.h ChnMsg -o $@

$(JAVA_SRC_DIR)/Consts.java:
	$(NCG) -java-classname=$(PACKAGE).Consts -target=$(PLATFORM) $(INCLUDES) $(MCTORRENT_ROOTDIR)/tos/lib/McTorrent/McTorrentC.nc McTorrent.h Msg.h Consts -o $@

clean:
	rm -f $(MSGS)
	rm -f $(JAVA_SRC_DIR)/*.class

