COMPONENT=Surge
SENSORBOARD=micasb
XBOWROOT=${TOSROOT}/contrib/xbow/tos
XBOWBETAROOT=${TOSROOT}/contrib/xbow/beta/tos

# For MICA2 and MICA2DOT
#PFLAGS+= -I${XBOWROOT}/tos/platform/mica2 -I${XBOWROOT}/tos/CC1000RadioAck 

# For MICAZ
PFLAGS+= -I${XBOWBETAROOT}/lib/CC2420RadioAck -I${XBOWBETAROOT}/platform/micazack 

PFLAGS+= -I${XBOWROOT}/lib/ReliableRoute -I%T/lib/Queue -I%T/lib/Broadcast -I%T/lib/Attributes

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
