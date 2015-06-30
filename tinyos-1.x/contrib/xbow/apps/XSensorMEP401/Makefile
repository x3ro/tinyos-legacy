# $Id: Makefile,v 1.10 2005/04/06 04:13:01 husq Exp $
COMPONENT=TestSensor
SENSORBOARD=mep401

XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos

PFLAGS = -I$(XBOWROOT)/interfaces  -I$(XBOWROOT)/system -I$(XBOWROOT)/lib -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/AXStack/$(PLATFORM)
PFLAGS += -I$(XBOWROOT)/sensorboards/$(SENSORBOARD) -I$(TOSROOT)/tos/sensorboards/micawb

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
