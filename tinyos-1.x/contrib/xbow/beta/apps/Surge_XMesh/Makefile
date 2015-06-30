COMPONENT=Surge
SENSORBOARD=micasb


#USE THIS LINE FOR MICA2
PFLAGS=  -I../../tos/platform/mica2 -I../../tos/XStack -I../../tos/lib/XMesh -I%T/lib/Queue -I%T/lib/Broadcast -I../../tos/lib/TimeSync -DROUTE_UPDATE_INTERVAL=16000 -DINITIAL_TIMER_RATE=8000



#USE THIS LINE FOR MICAZ
PFLAGS=  -I../../tos/platform/micazack  -I../../tos/lib/CC2420RadioAck -I../../tos/lib/XMesh -I%T/lib/Queue -I%T/lib/Broadcast -I../../tos/lib/TimeSync -DROUTE_UPDATE_INTERVAL=15000 -DINITIAL_TIMER_RATE=8000

include ../MakeXbowlocal
include ${TOSROOT}/apps/Makerules
