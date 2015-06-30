COMPONENT=TestBVRSimple
include ../Makerules 

#Configuration Parameters
PFLAGS += -DMAX_ROOT_BEACONS=8   #c
PFLAGS += -DTOSH_DATA_LENGTH=30  #29 for c < 8; 30 for 8 coords; 42 for 12 coord components; 54 for 16;
PFLAGS += -DBVR_APP_DATA_LENGTH=10 # TOSH_DATA_LENGTH - (12 + MAX_ROOT_BEACONS)
PFLAGS += -DLE_CACHE_SIZE=18

#Testing
#CFLAGS += -DLINK_DUMMY #uncomment to use dummy link estimator
#CFLAGS += -DFROZEN_COORDS

#Experimentation
CFLAGS += -DEXP_PROGRESS #uses the expected progress when ranking next_hops
CFLAGS += -DBEACON_ETX   
CFLAGS += -DETX_TOLERANCE

#Includes
PFLAGS += -I$(BASEDIR)/tos/bvr -I$(BASEDIR)/tos/commstack 
PFLAGS += -I$(BASEDIR)/tos/interfaces -I$(BASEDIR)/tos/linkestimator -I$(BASEDIR)/tos/util
PFLAGS += -I$(BASEDIR)/tos/command -I%T/lib/Queue

ifeq ($(PLATFORM), pc)
PFLAGS += -I. -I../../tos/TOSSIM-is -I%T/../beta/TOSSIM-packet
endif



