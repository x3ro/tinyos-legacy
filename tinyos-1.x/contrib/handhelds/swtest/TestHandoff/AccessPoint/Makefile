# When building consider using the following options:
#
#    CC2420_CHANNEL=number         Set the radio channel
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address   (REQUIRED)
#    SSID=string                   Set the SSID of the access point
#    PAN_ID=number                 Set the PAN_ID of the access point to a 16 bit value
#    IP=x.x.x.x                    Set the local IP address of the access point     (REQUIRD)
#    MSG_POOL=number               Number of buffers to allocate to the message pool
#    
# For example, to use channel 26, try:
#
#    make CC2420_CHANNEL=26 SSID="CRL" PAN_ID=0xabcd telos

COMPONENT=AccessPoint

USE_IP=True
USE_RADIO=True

include ../../Makerules

ifdef PAN_ID
PFLAGS += -DPAN_ID="$(PAN_ID)"
endif

ifdef MSG_POOL
PFLAGS += -DDEF_MSG_POOL_SIZE=$(MSG_POOL)
else
ifeq ($(PLATFORM),telosb)
PFLAGS += -DDEF_MSG_POOL_SIZE=40
else
PFLAGS += -DDEF_MSG_POOL_SIZE=8
endif
endif

PFLAGS += -DSMCLK_DIVISOR=0


# catch-all rule - pass targets on to the lower level
clean cleanall:
	rm -rf build doc *.pyc
	make -C kernel clean
	make -C daemon clean
