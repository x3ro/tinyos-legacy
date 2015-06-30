COMPONENT=RemoteLuC
MSG_SIZE=30

#------------------------------ Platform -----------------------------------#

PFLAGS+= -DTELOS_PLATFORM
#PFLAGS+= -DSIM_TELOS_PLATFORM
#PFLAGS+= -DMAKE_PC_PLATFORM
#PFLAGS+= -DMICA2_PLATFORM

#--------------------------------- Flags -----------------------------------#

PFLAGS+= -DENABLE_ACK

#--------------------- Platform-specific sensor component ------------------#

#------------------------------- Libraries ---------------------------------#

#CFLAGS=-I$/../OscopeRF

PFLAGS += -I%T/lib/Util

PFLAGS += -I$/../ULLA -I$/../SensorMeter 
#-I$/../Header
PFLAGS += -I%T/lib/MultiHopLQI -I%T/lib/Queue
#PFLAGS += -I$/../MultiHopLQI -I%T/lib/Queue

include $(MAKERULES)


