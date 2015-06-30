# $Id: Makefile,v 1.9 2004/08/20 06:36:18 mturon Exp $
COMPONENT=TestSensor
SENSORBOARD=mep500

#NESC_FLAGS = -Wnesc-all -v
XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

# ** Low Power Route
#PFLAGS  = -I$(XBOWBETAROOT)/platform/mica2dot
#PFLAGS += -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I$(XBOWROOT)/CC1000RadioPulse
#PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute_Low_Power
#PFLAGS += -I%T/lib/Queue
#PFLAGS += -I%T/lib/Broadcast

# ** Reliable Route
#PFLAGS  = -I$(XBOWBETAROOT)/platform/mica2dot
#PFLAGS += -I$(XBOWROOT)/platform/mica2 
#PFLAGS += -I$(TOSROOT)/beta/CC1000RadioAck
#PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute
#PFLAGS += -I%T/lib/Queue

# ** Reliable Route Time Sync
PFLAGS  = -I$(XBOWBETAROOT)/platform/mica2dot
PFLAGS += -I$(XBOWBETAROOT)/platform/mica2
PFLAGS += -I$(XBOWBETAROOT)/CC1000RadioSync
PFLAGS += -I$(XBOWBETAROOT)/lib/ReliableRoute_Sync
PFLAGS += -I%T/lib/Queue
PFLAGS += -I$(XBOWBETAROOT)/lib/TimeSync

PFLAGS += -I$(XBOWROOT)/sensorboards/$(SENSORBOARD) \
	  -I$(TOSROOT)/tos/sensorboards/micawb

# Required by Deluge
PFLAGS += -DDELUGE_GENERIC_COMM_PROMISCUOUS
TINYOS_NP=BNP

PFLAGS += -DUSE_433_MHZ

#PFLAGS += -DTEN_X

MSG_SIZE=44

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
