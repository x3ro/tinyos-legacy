# $Id: makefile,v 1.4 2004/09/03 09:19:25 husq Exp $
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
PFLAGS = -I$(XBOWBETAROOT)/interfaces  -I$(XBOWBETAROOT)/system -I$(XBOWBETAROOT)/lib -I$(XBOWBETAROOT)/platform/mica2 -I$(XBOWBETAROOT)/sensorboards/$(SENSORBOARD)
COMPONENT=MyAppConfig
include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules




