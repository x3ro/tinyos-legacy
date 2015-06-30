#$Id: Makefile,v 1.1 2005/04/16 01:01:45 phoebusc Exp $
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


PACKAGE = net.tinyos.RobotTB.MagLocalAggRpt
#APPDIR=$(UCBROBODIR)/apps/MagDirectBot
APPCOMPILEDIR=$(UCBROBODIR)/apps/sensornet/MagLocalAggRpt

## Flags for MIG and NCG
MIG_NCG_FLAGS = \
-target=mica2dot \
-board=honeydot \
-I$(APPCOMPILEDIR) \
-I$(INCLUDEDIR) \
-I$(UCBROBODIR)/interfaces \
-I$(UCBROBODIR)/lib/sensornet \
-I$(UCBROBODIR)/lib \
-I$(UCBROBODIR)/lib/sensornet/PEGmagsensor \
-I$(CONTRIBDIR)/ucb/tos/sensorboards/honeydot
#-I$(CONTRIBDIR)/PEGSensor/magsensor \
#-I$(CONTRIBDIR)/SystemC/common \



# LIST of message classes to build
MSGS = MagReportMsg.java MagLeaderReportMsg.java MagQueryConfigMsg.java MagLocalAggRptConst.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig


include $(ROOT)/Makefile.include

MagLeaderReportMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagLeaderReportMsg $(INCLUDEDIR)/MagSNMsgs.h MagLeaderReportMsg -o $@
	$(JAVAC) $@

MagReportMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagReportMsg $(INCLUDEDIR)/MagSNMsgs.h MagReportMsg -o $@
	$(JAVAC) $@

MagQueryConfigMsg.java:
	$(MIG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagQueryConfigMsg $(INCLUDEDIR)/MagSNMsgs.h MagQueryConfigMsg -o $@
	$(JAVAC) $@

MagLocalAggRptConst.java:
	$(NCG) $(MIG_NCG_FLAGS) -java-classname=$(PACKAGE).MagLocalAggRptConst $(APPCOMPILEDIR)/MagLocalAggRpt.nc MagLocalAggRptConst.h MagSNMsgs.h RobotTB_AM.h MovAvgDetect_DiffRptM.h MagWtAvgLeadRptM.h -o $@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

