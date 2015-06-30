# $Id: makefile,v 1.1 2004/10/11 01:45:50 husq Exp $
# Choose the sensor board based on the platform.
# Pls make sure No other Sodebug.h in the way

XBOWROOT=%T/../contrib/xbow/tos
XBOWBETAROOT=%T/../contrib/xbow/beta/tos
#NESC_FLAGS = -Wnesc-all -v

LOCAL_PLATFORMS = mica2 mica2dot
LOCAL_PLATFORM := $(filter $(LOCAL_PLATFORMS), $(MAKECMDGOALS))
	ifeq ($(LOCAL_PLATFORM),mica2)
#		SENSORBOARD=MDA300CA
		SENSORBOARD=mts310
	endif
	ifeq ($(LOCAL_PLATFORM),mica2dot)
		SENSORBOARD = sensimeshdot
	endif
PFLAGS = -I$(XBOWBETAROOT)/lib/Xee -I$(XBOWROOT)/platform/$(PLATFORM) -I$(XBOWROOT)/sensorboards/$(SENSORBOARD)

COMPONENT=MyAppConfig
include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules




