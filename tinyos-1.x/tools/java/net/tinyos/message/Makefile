
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java
SUBDIRS = avrmote telos micaz

ROOT = ../../..
include $(ROOT)/Makefile.include

BaseTOSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).BaseTOSMsg $(TOS)/system/AM.h TOS_Msg -o $@
	@echo
	@echo '************** WARNING ***************'
	@echo
	@echo You have rebuilt BaseTOSMsg.java. Assuming you really meant to do this,
	@echo you should now edit it to remove static from the following methods:
	@echo totalSize_data totalSizeBits_data
	@echo 'numElements_data() numElements_data(int dimension)'
	@echo offset_crc offsetBits_crc



