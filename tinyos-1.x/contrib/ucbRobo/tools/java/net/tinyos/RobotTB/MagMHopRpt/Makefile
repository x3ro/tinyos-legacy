##########Generic Stuff##########
ifndef UCBROBODIR
UCBROBODIR := $(shell ncc -print-tosdir)/../contrib/ucbRobo
endif
ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif
ifndef INCLUDEDIR
INCLUDEDIR := $(UCBROBODIR)/include
endif
ROOT := $(shell ncc -print-tosdir)/../tools/java
MIG = mig java
NCG = ncg java
#################################


PACKAGE = net.tinyos.RobotTB.MagMHopRpt
APPCOMPILEDIR=$(UCBROBODIR)/apps/sensornet/MagMHopRpt


## Flags for MIG and NCG
MIG_NCG_FLAGS = \
-target=mica2dot \
-board=honeydot \
-I$(APPCOMPILEDIR) \
-I$(INCLUDEDIR) \
-I$(CONTRIBDIR)/PEGSensor/magsensor
# We use PEGSensor directory because NesC apps use MagSensor.nc, not 
# MagSensorTypes.nc for MagLightTrail.  See the makefile for MagMHopRpt
# for more detail


# LIST of message classes to build
MSGS = MagReportMhopMsg.java MagQueryRptMhopMsg.java MagQueryConfigBcastMsg.java MagDebugMsg.java MagMHopRptConst.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig


include $(ROOT)/Makefile.include

MagReportMhopMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagReportMhopMsg $(INCLUDEDIR)/MagSNMhopMsgs.h MagReportMhopMsg_MIG -o $@
	$(JAVAC) $@

MagQueryRptMhopMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagQueryRptMhopMsg $(INCLUDEDIR)/MagSNMhopMsgs.h MagQueryRptMhopMsg_MIG -o $@
	$(JAVAC) $@

MagQueryConfigBcastMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagQueryConfigBcastMsg $(INCLUDEDIR)/MagSNMhopMsgs.h MagQueryConfigBcastMsg_MIG -o $@
	$(JAVAC) $@

MagDebugMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagDebugMsg $(INCLUDEDIR)/MagSNMhopMsgs.h MagDebugMsg -o $@
	$(JAVAC) $@

#Only works if use the M file as the top level file
MagMHopRptConst.java:
	$(NCG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagMHopRptConst $(APPCOMPILEDIR)/MagMHopRptM.nc MagMHopRptConst.h MagSNMhopMsgs.h RobotTB_AM.h -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

