COMPONENT=Surge
SENSORBOARD=micasb

PFLAGS=  -I../../tos/platform/mica2 -I../../tos/CC1000RadioSync -I../../tos/lib/ReliableRoute_Sync -I%T/lib/Queue -I%T/lib/Broadcast -I../../tos/lib/TimeSync
include ../MakeXbowlocal
include ${TOSROOT}/tools/make/Makerules

PROGRAMMER_PART += --wr_fuse_l=c4

#PFLAGS +=-DFREQ_433_MHZ
#PFLAGS += -DDELUGE_GENERIC_COMM_PROMISCUOUS
#PFLAGS += -DTEN_X
