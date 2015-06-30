COMPONENT=Surge
SENSORBOARD=micasb
#TINYSEC=true

# For MICA2 and MICA2DOT
PFLAGS+= -I../../tos/platform/mica2 -I../../tos/CC1000RadioAck -I../../tos/lib/ReliableRoute -I%T/lib/Queue -I%T/lib/Broadcast -I%T/lib/Attributes

# For MICAZ
#PFLAGS+= -I../../beta/tos/lib/CC2420RadioAck -I../../beta/tos/platform/micazack -I../../tos/lib/ReliableRoute -I%T/lib/Queue -I%T/lib/Broadcast -I%T/lib/Attributes

include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules
