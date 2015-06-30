COMPONENT=Appl

IFRCROOT=${TOSROOT}/contrib/usc-ifrc/
PFLAGS=-I${IFRCROOT}/apps/RateControl -I${IFRCROOT}/apps/Report -I${IFRCROOT}/contrib/ucb/tos/lib/MultiHopLQI -I${IFRCROOT}/tos/lib/CC2420Radio -I${IFRCROOT}/tos/lib/RateControlQueue -I${IFRCROOT}/tos/system


# Avoid using default group and default frequency. 
DEFAULT_LOCAL_GROUP=0x5f
CFLAGS+=-DCC2420_DEF_CHANNEL=20
# Decrease the TX power
CFLAGS+=-DCC2420_DEF_RFPOWER=0x3
CFLAGS+=-DTOSH_DATA_LENGTH=36

# Changes to Standard module will come into effect
# with these define and other #define needed for 
# the Rate control code to compile
CFLAGS+="-DCONG_CONTROL "

# IFRC Parameters
CFLAGS+="-DMAX_NODES=50"
CFLAGS+="-DMAX_NEIGH=20"

CFLAGS+="-DRESOLUTION=10000"
# This will change depending upon the number of nodes 
#CFLAGS+="-DSSVALUE=60000"
CFLAGS+="-DSSVALUE=200"

#CFLAGS+="-DTESTEPSILON"
CFLAGS+="-DEPSILON=80"
CFLAGS+="-DBANDWIDTH=600000"
CFLAGS+="-DPHI=SSVALUE/8"


CFLAGS+="-DPARAM_MINTHR=4"
CFLAGS+="-DPARAM_MAXTHR=8"
CFLAGS+="-DPARAM_INC=8"
# Forget neighbour if a total of AGELIMIT packets
# have been received(for nodes other than the neighbor)
# since last packet from neighbour
CFLAGS+="-DAGELIMIT=50"


# Queue Management 
# See QueuedSend.nc too
CFLAGS+="-DALPHA=3" #  w_{q} = ALPHA/100
CFLAGS+="-DIFRC_MAX_TRANSMIT=5 "
CFLAGS+="-DIFRC_QUEUE_SIZE=64 "
CFLAGS+="-DSEND_TIMEOUT=200 "
#PFLAGS+=-I%T/lib/RateControlQueue


#If FIXROUTE is not specified routes are
#selected dynamically

# Just used to separate routing code from IFRC code
CFLAGS+="-DROUTING "
CFLAGS+="-DROUTE_STAB_TIME=1"


#For the routing module
#See MultiHopLQI/MultiHopLQI.nc
CFLAGS+="-DPTHRESH"
CFLAGS+="-DPARENTTHRESH=90"
CFLAGS+="-DPCOUNT=10"
#PFLAGS+=-I%T/../contrib/ucb/tos/lib/MultiHopLQI

# See CC2420RadioM.nc and CC2420Const.h
CFLAGS+="-DSACK " 
CFLAGS+="-DACK_DELAY=150"



################ For Experiments #####################
#Static Routing
CFLAGS+="-DFIXROUTE"

#Allow parents to change during the run of the experiment. 
#CFLAGS+="-DPCALLOWED"

CFLAGS+="-DBS_ADDRESS=1"

CFLAGS+="-DBEACONFACTOR=3"

#Node addition and deletion
#CFLAGS+="-DDYNAMICS"
CFLAGS+="-DDTIME=1200"

#CFLAGS+="-DFIXRATE"
#CFLAGS+="-DRATE=10000"

# For Subset of node sending data
#CFLAGS+="-DSUBSET"
# For Weighted Fair Queue
#CFLAGS+="-DWFQ"




# Logging
# For getting various status information
#PFLAGS+=-I../Report/
CFLAGS+="-DAM_LOG=245"
CFLAGS+="-DSERIAL_QUEUE_SIZE=32"

CFLAGS+="-DLOG_RLOCAL"
CFLAGS+="-DLOG_NEIGH"
#CFLAGS+="-DLOG_LQI"
#CFLAGS+="-DLOG_PACKLOSS"
#CFLAGS+="-DLOG_LATENCY"
CFLAGS+="-DLOG_TPUT"
#CFLAGS+="-DLOG_TRANS"
CFLAGS+="-DLOG_LINKLOSS"
CFLAGS+="-DLOG_QUEUE"
#CFLAGS+="-DLOG_SDLOSS"
CFLAGS+="-DLOG_INFO"

# For Debugging
CFLAGS+="-DAM_DEBUG=250 "
#CFLAGS+="-DDEBUG "
#CFLAGS+="-DDEBUG_AM"
#CFLAGS+="-DDEBUG_MAC"



include ../Makerules



