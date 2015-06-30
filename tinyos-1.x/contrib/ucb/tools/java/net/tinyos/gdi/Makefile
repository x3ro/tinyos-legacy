TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.gdi
APP=$(TOS)/../contrib/ucb/apps/TestLabApp
MIG = mig java

# List of message classes to build
MSGS = GDI2SoftWSMsg.java GDI2SoftBMsg.java GDI2SoftCalibMsg.java GDI2SoftAckMsg.java ThermopileReadMsg.java ThermopileWriteMsg.java ThermopileAckMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

GDI2SoftWSMsg.java:
	$(MIG) -java-classname=$(PACKAGE).GDI2SoftWSMsg $(APP)/GDI2SoftMsg.h GDI2Soft_WS_Msg >$@

GDI2SoftBMsg.java:
	$(MIG) -java-classname=$(PACKAGE).GDI2SoftBMsg $(APP)/GDI2SoftMsg.h GDI2Soft_B_Msg >$@

GDI2SoftCalibMsg.java:
	$(MIG) -java-classname=$(PACKAGE).GDI2SoftCalibMsg $(APP)/GDI2SoftMsg.h GDI2Soft_Calib_Msg >$@

GDI2SoftAckMsg.java:
	$(MIG) -java-classname=$(PACKAGE).GDI2SoftAckMsg $(APP)/GDI2SoftMsg.h GDI2Soft_Ack_Msg >$@

ThermopileReadMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ThermopileReadMsg $(APP)/GDI2SoftMsg.h Thermopile_Read_Msg >$@

ThermopileWriteMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ThermopileWriteMsg $(APP)/GDI2SoftMsg.h Thermopile_Write_Msg >$@

ThermopileAckMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ThermopileAckMsg $(APP)/GDI2SoftMsg.h Thermopile_Ack_Msg >$@

cleanmig:
	rm -f $(MSGS)
