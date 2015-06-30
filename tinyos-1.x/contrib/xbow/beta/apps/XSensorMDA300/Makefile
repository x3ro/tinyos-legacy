COMPONENT=XSensorMDA300
SENSORBOARD=mda300 
XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

# ** Low Power Route
#PFLAGS  = -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I$(XBOWROOT)/CC1000RadioPulse
#PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute_Low_Power
#PFLAGS += -I%T/lib/Queue
#PFLAGS += -I%T/lib/Broadcast

# ** Reliable Route
#PFLAGS  = -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I$(XBOWROOT)/CC1000RadioAck
#PFLAGS += -I$(XBOWROOT)/lib/ReliableRoute
#PFLAGS += -I%T/lib/Queue

# ** Reliable Route Time Sync
PFLAGS  = -I$(XBOWBETAROOT)/platform/mica2
PFLAGS += -I$(XBOWBETAROOT)/CC1000RadioSync
PFLAGS += -I$(XBOWBETAROOT)/lib/ReliableRoute_Sync
PFLAGS += -I%T/lib/Queue
PFLAGS += -I$(XBOWBETAROOT)/lib/TimeSync

# use AWoo's MintRoute as routing layer
#PFLAGS  = -I$(XBOWROOT)/platform/mica2
#PFLAGS += -I%T/lib/MintRoute -DMULTIHOPROUTER=WMEWMAMultiHopRouter
#PFLAGS += -I%T/lib/Queue

PFLAGS += -I$(XBOWROOT)/interfaces  
PFLAGS += -I$(XBOWROOT)/system 
PFLAGS += -I$(XBOWROOT)/lib 
PFLAGS += -I$(XBOWROOT)/sensorboards/$(SENSORBOARD) 

PROGRAMMER_EXTRA_FLAGS = -v=2
PFLAGS += -DFREQ_433_MHZ
#PFLAGS += -DTEN_X

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules

