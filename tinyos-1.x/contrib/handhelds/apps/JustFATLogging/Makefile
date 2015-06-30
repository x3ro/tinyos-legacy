# When building consider using the following options:
#
#    CURRENT_TIME=`python ./timeSec.py'           Set the time on the clock to current time. no ntp means you need a good starting point

COMPONENT=JustFATLogging

#USE_IP=True
#SELECT_WIRED_OR_WIRELESS=True

# we have to do this when we don't use the radio
PFLAGS += -DID_CHIP=$(USE_ID_CHIP)

ifdef CURRENT_TIME
PFLAGS += -DCURRENT_TIME=$(CURRENT_TIME)
endif

include ../Makerules
