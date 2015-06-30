# $Id: Makefile,v 1.3 2005/02/27 23:20:35 husq Exp $
COMPONENT=TestSkyeReadMini

PFLAGS += -I../../tos/platform/mica2

PFLAGS += -I../../tos/sensorboards/SkyeReadMini
PFLAGS += -I../../tos/sensorboards/SkyeReadMini/MiniComm
PFLAGS += -I../../tos/sensorboards/SkyeReadMini/MiniPacketizer

include ../MakeXbowlocal

CFLAGS += -DSEND_TO_RADIO=1

include ${TOSROOT}/tools/make/Makerules
