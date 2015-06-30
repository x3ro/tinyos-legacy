# $Id: Makefile,v 1.1 2004/11/15 03:52:08 husq Exp $
COMPONENT=TestSensor
SENSORBOARD=mts310

XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

# Add routing layer linkage
#PFLAGS += -I${TOSROOT}/beta/CC1000RadioAck -I../../tos/lib/ReliableRoute -I%T/lib/Queue

# ** Reliable Route
PFLAGS = -I$(XBOWROOT)/platform/mica2
PFLAGS += -I$(XBOWROOT)/CC1000RadioAck
PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute
PFLAGS += -I%T/lib/Queue

# use AWoo's MintRoute as routing layer
#PFLAGS = -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I%T/lib/MintRoute -DMULTIHOPROUTER=WMEWMAMultiHopRouter
#PFLAGS += -I%T/lib/Queue

# ** Reliable Low Power Route
#PFLAGS = -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I$(XBOWROOT)/CC1000RadioPulse
#PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute_Low_Power
#PFLAGS += -I%T/lib/Queue
#PFLAGS += -I%T/lib/Broadcast

# ** Reliable Route Time Sync
#PFLAGS += -I$(XBOWBETAROOT)/platform/mica2
#PFLAGS += -I$(XBOWBETAROOT)/CC1000RadioSync
#PFLAGS += -I$(XBOWBETAROOT)/lib/ReliableRoute_Sync
#PFLAGS += -I%T/lib/Queue
#PFLAGS += -I$(XBOWBETAROOT)/lib/TimeSync

# ******* Standard includes ************
PFLAGS += -I$(XBOWBETAROOT)/lib/Xee -I$(XBOWROOT)/interfaces -I$(XBOWROOT)/system -I$(XBOWROOT)/lib 
PFLAGS += -I$(XBOWROOT)/sensorboards/$(SENSORBOARD) 

# Required by Deluge
#PFLAGS += -DDELUGE_GENERIC_COMM_PROMISCUOUS
#TINYOS_NP=BNP

#PFLAGS += -DFREQ_433_MHZ
#PFLAGS += -DTEN_X

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules

