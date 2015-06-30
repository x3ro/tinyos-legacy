COMPONENT=TestMTS400
SENSORBOARD=mts400


XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

PFLAGS= -I$(XBOWROOT)/interfaces  -I$(XBOWROOT)/system  -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM) -I$(XBOWROOT)/lib -I$(XBOWROOT)/sensorboards/$(SENSORBOARD)

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
