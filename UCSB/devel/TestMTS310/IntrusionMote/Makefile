COMPONENT=TestSensors
SENSORBOARD=mts310


XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

UCSBROOT=%T/../contrib/UCSB/tos

PFLAGS= -I$(XBOWROOT)/interfaces  -I$(XBOWROOT)/system  
PFLAGS+= -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM) 
PFLAGS+= -I$(XBOWROOT)/lib  -I$(UCSBROOT)/interfaces -I$(UCSBROOT)/lib/MTS310 
PFLAGS+= -I$(UCSBROOT)/sensorboards/$(SENSORBOARD)

include ../../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
