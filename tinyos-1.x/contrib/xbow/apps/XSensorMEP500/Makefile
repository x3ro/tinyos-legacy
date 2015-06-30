# $Id: Makefile,v 1.6 2005/04/06 04:20:31 husq Exp $
XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

COMPONENT=TestSensor
SENSORBOARD=mep500

PFLAGS = -I$(XBOWROOT)/interfaces  -I$(XBOWROOT)/system -I$(XBOWROOT)/lib -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM)
PFLAGS += -I$(XBOWROOT)/sensorboards/$(SENSORBOARD) -I$(TOSROOT)/tos/sensorboards/micawb

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules

