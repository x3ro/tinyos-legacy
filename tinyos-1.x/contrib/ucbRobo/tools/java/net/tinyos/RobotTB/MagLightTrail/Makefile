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


PACKAGE = net.tinyos.RobotTB.MagLightTrail
APPCOMPILEDIR=$(UCBROBODIR)/apps/sensornet/MagLightTrail


## Flags for MIG and NCG
MIG_NCG_FLAGS = \
-target=mica2dot \
-board=honeydot \
-I$(APPCOMPILEDIR) \
-I$(UCBROBODIR)/include \
-I$(CONTRIBDIR)/PEGSensor/magsensor
# We use PEGSensor directory because NesC apps use MagSensor.nc, not 
# MagSensorTypes.nc for MagLightTrail.  See the makefile for MagLightTrail
# for more detail


# LIST of message classes to build
MSGS = MagReportMsg.java MagQueryConfigMsg.java MagLightConst.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig


include $(ROOT)/Makefile.include

MagReportMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagReportMsg $(APPCOMPILEDIR)/MagMsg.h MagReportMsg -o $@
	$(JAVAC) $@

MagQueryConfigMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagQueryConfigMsg $(APPCOMPILEDIR)/MagMsg.h MagQueryConfigMsg -o $@
	$(JAVAC) $@

# Cheating a little bit by using the M file as the top level file
# The constants listed below are not recognized (because in .nc files, 
#     not in C files?)
MagLightConst.java:
	$(NCG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagLightConst $(APPCOMPILEDIR)/MagLightTrailM.nc MagMsg.h RobotTB_AM.h DEFAULT_REPORT_THRESH DEFAULT_NUM_FADE_INTERVALS DEFAULT_READ_FIRE_INTERVAL DEFAULT_FADE_FIRE_INTERVAL -o $@
	$(JAVAC) $@

## Old version using just MagMsg.h; may work
#MagLightConst.java:
#	$(NCG) -I$(APPCOMPILEDIR) -java-classname=$(PACKAGE).MagLightConst $(APPCOMPILEDIR)/MagMsg.h MagMsg.h -o $@
#	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

