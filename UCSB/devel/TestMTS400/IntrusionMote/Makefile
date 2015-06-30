COMPONENT=TestSensors
SENSORBOARD=mts400


XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

UCSBROOT=%T/../contrib/UCSB/tos

PFLAGS= -I$(XBOWROOT)/interfaces  -I$(XBOWROOT)/system  
PFLAGS+= -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM) 
PFLAGS+= -I$(XBOWROOT)/lib -I$(UCSBROOT)/sensorboards/$(SENSORBOARD) 
PFLAGS+= -I$(UCSBROOT)/interfaces -I$(UCSBROOT)/lib/MTS400


include ../../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
