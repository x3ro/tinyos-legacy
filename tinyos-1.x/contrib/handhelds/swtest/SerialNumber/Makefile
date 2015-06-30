# When building consider using the following options:
#
#    SSID=string                   Set the SSID of the access point
#    IP=x.x.x.x                    Set the IP address of the access point
#    HOST_IP=x.x.x.x   	           Uses wired operation and sets HOST_IP='x.x.x.x'
#    
# For example:
#
#    make SSID="CRL" IP='16.11.5.30' telosb       ---> Builds Wireless
#    make HOST_IP='16.11.5.50' IP='16.11.5.51' telosb             ---> Builds Wired
# 

COMPONENT=SerialNumber

USE_IP=True
SELECT_WIRED_OR_WIRELESS=True

include ../Makerules

ifndef USE_ID_CHIP
$(error You can only build this against a platform that has an ID chip)
else
PFLAGS += -DID_CHIP=$(USE_ID_CHIP)
ifdef HAS_ID_CHIP_POWER
PFLAGS += -DID_CHIP_POWER
endif
endif



