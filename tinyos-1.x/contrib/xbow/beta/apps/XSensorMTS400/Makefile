COMPONENT=TestMTS400
SENSORBOARD=mts400

MSG_SIZE=120
XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

PFLAGS=-I$(XBOWBETAROOT)/lib/Xee -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM) -I$(XBOWROOT)/lib -I$(XBOWBETAROOT)/sensorboards/$(SENSORBOARD) -I$(XBOWBETAROOT)/sensorboards/$(SENSORBOARD)/gps

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
