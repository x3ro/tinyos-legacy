# $Id: Makefile,v 1.1 2005/07/22 17:52:37 jwhui Exp $
#
# TinyOS Tools Makefile
#
# @author  TinyOS Team
#

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.deluge

MIG = mig java
NCG = ncg java

MSGS = DelugeAdvMsg.java DelugeReqMsg.java DelugeDataMsg.java DelugeDataMsg.java DelugeConsts.java NetProgMsg.java

INITIAL_TARGETS = $(MSGS)

OTHER_CLEAN = cleanmig

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include

#
# Deluge
#

DELUGE_PLATFORM=telosb
DELUGE_LIB=$(TOS)/lib/Deluge
INCLUDES=-I$(DELUGE_LIB) -I$(TOS)/lib/CC2420Radio

DelugeAdvMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeAdvMsg -target=$(DELUGE_PLATFORM) $(INCLUDES) $(DELUGE_LIB)/DelugeMsgs.h DelugeAdvMsg -o $@

DelugeReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeReqMsg -target=$(DELUGE_PLATFORM) $(INCLUDES) $(DELUGE_LIB)/DelugeMsgs.h DelugeReqMsg -o $@

DelugeDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeDataMsg -target=$(DELUGE_PLATFORM) $(INCLUDES) $(DELUGE_LIB)/DelugeMsgs.h DelugeDataMsg -o $@

NetProgMsg.java:
	$(MIG) -java-classname=$(PACKAGE).NetProgMsg -target=$(DELUGE_PLATFORM) $(INCLUDES) $(DELUGE_LIB)/NetProgMsgs.h NetProgMsg -o $@

DelugeConsts.java:
	$(NCG) -java-classname=$(PACKAGE).DelugeConsts -target=$(DELUGE_PLATFORM) $(INCLUDES) $(DELUGE_LIB)/DelugeC.nc Deluge.h DelugePageTransfer.h DelugeMsgs.h DelugeConsts -o $@

#
# Clean
#

cleanmig:
	rm -f $(MSGS)
