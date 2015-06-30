# When building consider using the following options:
#
#    CC2420_CHANNEL=number         Set the radio channel
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address   (REQUIRED)
#    SSID=string                   Set the SSID of the access point
#    PAN_ID=number                 Set the PAN_ID of the access point to a 16 bit value
#    IP=x.x.x.x                    Set the local IP address of the access point     (REQUIRD)
#    
# For example, to use channel 26, try:
#
#    make CC2420_CHANNEL=26 SSID="CRL" PAN_ID=0xabcd telos

include ../Makerules

ifneq ($(TARGETS:clean%=clean),clean)
ifdef CODE
COMPONENT="Radio$(CODE)"
else
$(error You must specify a CODE to compile such as Noise, UART, Send, or Test)
endif
endif


ifeq ($(CODE),UART)
USE_RADIO=True
else
USE_IP=True
SELECT_WIRED=True
USE_RADIO=True
endif

PFLAGS += -DSMCLK_DIVISOR=0

ifdef PAN_ID
PFLAGS += -DPAN_ID="$(PAN_ID)"
endif






