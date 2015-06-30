
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

ROOT = ../../../..
include $(ROOT)/Makefile.include


#TO REMAKE BaseTOSMsg, uncomment the line below and type make micaz msg
#include $(TOS)/../apps/Makerules

AM =  $(TOS)/platform/micaz/AM.h

msg: FORCE
	$(MIG) $(PFLAGS) $(CFLAGS) -java-classname=$(PACKAGE).$(PLATFORM).BaseTOSMsg  $(AM) TOS_Msg -o BaseTOSMsg.java
	@echo
	@echo '************** WARNING ***************'
	@echo
	@echo You have rebuilt BaseTOSMsg.java. Assuming you really meant to do this,
	@echo you should now edit it to remove static from the following methods:
	@echo totalSize_data totalSizeBits_data
	@echo 'numElements_data() numElements_data(int dimension)'
	@echo offset_crc offsetBits_crc


