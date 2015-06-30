COMPONENT=TASKApp

#SENSORBOARD=mep500
#PFLAGS = -I../../contrib/xbow/tos/sensorboards/mep500 -I$(TOSROOT)/tos/sensorboards/micawb
#be sure to get hardware.h from contrib/xbow/beta/tos/platform/mica2dot/hardware.h
#be sure to set fuses correctly: PROGRAMMER_PART=--wr_fuse_e=ff --wr_fuse_h=d9 --wr_fuse_l=c4

SENSORBOARD=mep401
PFLAGS = -I../../contrib/xbow/tos/sensorboards/mep401 -I$(TOSROOT)/tos/sensorboards/micawb

#SENSORBOARD=mda300ca
#PFLAGS = -I../../contrib/xbow/tos/sensorboards/mda300ca
 
PFLAGS += -I%T/lib/Util
PFLAGS += -I%T/lib/Attributes 
PFLAGS += -I%T/lib/Commands 
PFLAGS += -I%T/lib/TinyDB
PFLAGS += -I%T/lib/Queue
PFLAGS += -I%T/lib/FS
PFLAGS += -I%T/lib/TinyDB/Aggregates
PFLAGS += -fno-strict-aliasing

#PFLAGS += -I../../contrib/xbow/tos/CC1000Pulse
#PFLAGS += -I../../contrib/xbow/tos/lib/ReliableRoute_Low_Power

#PFLAGS += -I../../contrib/xbow/tos/CC1000RadioPulse
#PFLAGS += -I../../contrib/xbow/tos/lib/ReliableRoute_Low_Power

#PFLAGS += -I../../contrib/xbow/beta/tos/CC1000RadioSync
#PFLAGS += -I../../contrib/xbow/beta/tos/lib/ReliableRoute_Sync
#PFLAGS += -I../../contrib/xbow/beta/tos/lib/TimeSync

#PFLAGS += -fnesc-include=CompileDefines
#PFLAGS += -DUSE_LOW_POWER_LISTENING
#PFLAGS += -DMULTIHOPROUTER=EWMAMultiHopRouter

PFLAGS += -I%T/lib/MintRoute

PFLAGS += -DNETWORK_OF_MEP401_AND_MEP500

#MSG_SIZE=54
MSG_SIZE=49

include ../Makerules
