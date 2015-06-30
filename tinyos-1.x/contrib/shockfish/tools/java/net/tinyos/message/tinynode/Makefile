#For these classes to be used, one must add /contrib/shockfish/tools/java to the CLASSPATH
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include


#TO REMAKE BaseTOSMsg, uncomment the line below and type make tinynode msg 
#include $(TOS)/../contrib/shockfish/apps/Makerules

# [henridf] well, apparently this never worked (even for Remy) -- some weird make problem
# where it warns 'Makefile:16: warning: overriding commands for target `msg'' and then gets the build command messed up.
# for now, i got away with it by munging the command obtained with telos:
# mig java -mdisable-hwmul -I/home/henridf/work/tinyos-1.1.10/tos/lib/CC2420Radio -I/home/henridf/work/tinyos-1.1.10/tos/lib/Flash -I%T/lib/Deluge -I%T/lib/Deluge/TOSBoot/include -Wl,--section-start=.text=0x3000,--defsym=_reset_vector__=0x1100 -Wall -Wshadow -DDEF_TOS_AM_GROUP=0x7d -Wnesc-all -target=tinynode -fnesc-cfile=build/tinynode/app.c -board= -DIDENT_USER_ID="henridf" -DIDENT_USER_ID_BYTES="104,101,110,114,105,100,102,0" -DIDENT_HOSTNAME="tinyblue" -DIDENT_HOSTNAME_BYTES="116,105,110,121,98,108,117,101,0" -DIDENT_USER_HASH=0xf2bc8a0dL -DIDENT_UNIX_TIME=0x4238b5f9L -java-classname=net.tinyos.message.tinynode.BaseTOSMsg  /home/henridf/work/tinyos-1.1.10/contrib/shockfish/tos/platform/tinynode/AM.h TOS_Msg -o BaseTOSMsg.java


AM = $(TOS)/../contrib/shockfish/tos/platform/tinynode/AM.h

msg: FORCE
	$(MIG) $(PFLAGS) $(CFLAGS) -java-classname=$(PACKAGE).tinynode.BaseTOSMsg  $(AM) TOS_Msg -o BaseTOSMsg.java
	@echo
	@echo '************** WARNING ***************'
	@echo
	@echo You have rebuilt BaseTOSMsg.java. Assuming you really meant to do this,
	@echo you should now edit it to remove static from the following methods:
	@echo totalSize_data totalSizeBits_data
	@echo 'numElements_data() numElements_data(int dimension)'
	@echo offset_crc offsetBits_crc offset_data


