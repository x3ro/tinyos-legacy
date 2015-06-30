PFLAGS += -DDIAGMSG_RETRY_COUNT=2 -DDIAGMSG_BASE_STATION=TOS_BCAST_ADDR 
#-I%T/lib/IDs -DLOGICAL_IDS -DTIMESYNC_SYSTIME

PFLAGS += -DTIMESYNC_RATE=10L -DTS_POLLER_RATE=2
PFLAGS += -DSIMULATE_MULTIHOP 
PFLAGS += -I%T/lib/RapidTS -I%T/lib/FloodRoutingSync -DRITS_TIMESTAMP_LENGTH=4
PFLAGS += -I%T/lib/FloodRouting -I%T/lib/RemoteControl -I%T/lib/DiagMsg

ifndef COMPONENT
#polling node (single mote)
COMPONENT=TestTimeSyncPollerC

#synchronizing node (60 motes)
#COMPONENT=TestTimeSyncC

#the root (single mote)
#COMPONENT=TOSBase

endif

include ../Makerules
