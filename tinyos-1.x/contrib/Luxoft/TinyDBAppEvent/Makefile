##
# Makefile that build TinyDB test application
##

COMPONENT=TinyDBApp
SENSORBOARD=micasb
TDIR=$(shell ncc -print-tosdir)


# Uncomment this if you want ECC leds
#PFLAGS += -DLEDS 

#Uncomment this if you want to switch TinyDB Leds off
PFLAGS += -DTDBNOLEDS

#PFLAGS += -DINTMSG

PFLAGS += -DTRACEROUTE

PFLAGS += -D_WITH_CHANQ_
 
#PFLAGS += -DUSE_CQTEST

PFLAGS += -I../ECC -I../TraceRoute -I../IRSensor -I../Flood -I../Ping \
-I../ChannelQ \
-I$(TDIR)/lib/Attributes \
-I$(TDIR)/lib/Commands -I$(TDIR)/lib/TinyDB -I$(TDIR)/lib/Route \
-I$(TDIR)/lib/Queue  -I$(TDIR)/lib/FS -I$(TDIR)/lib/TinyDB/Aggregates \
-DNETWORK_MODULE=NetworkMultiHop -DGENERICCOMM=GenericCommPromiscuous \
-fno-strict-aliasing  -DLogicalTime=SimpleTime -DMH6_ROUTING \
-DTOSH_DATA_LENGTH=49 -DNTIMERS=20 -DMHOP_QUEUE_SIZE=4 -DSEND_QUEUE_SIZE=6 \
-DMAX_NUM_SERVICES=2 -DACK_ARRAY_SIZE=6 \
-Wpadded

MSG_SIZE=49
DEFAULT_LOCAL_GROUP=96

include ./Makerules

ifeq ($(PLATFORM),pc)
  PFLAGS += -L/usr/lib -I/usr/include
  PFLAGS += -DUSE_IRDETECT
else
  PFLAGS += -L/usr/avr/lib/avr5/ -I/usr/avr/include
  PFLAGS += -DUSE_IRDETECT
endif

ifeq ($(PLATFORM),mica2dot)
  PFLAGS := $(shell echo $(PFLAGS) | sed 's/board=micasb/board=none/g')
endif
#eof

