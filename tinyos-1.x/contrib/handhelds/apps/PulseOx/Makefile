# When building consider using the following options:
#
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address
#    SSID=string                   Set the SSID of the access point
#    IP=x.x.x.x                    Set the IP address of the access point
#    HOST_IP=x.x.x.x   	           Uses wired operation and sets HOST_IP='x.x.x.x'
#    
# For example:
#
#    make LONG_ADDRESS=15 SSID="CRL" IP='16.11.5.30' telosb       ---> Builds Wireless
#    make HOST_IP='16.11.5.50' IP='16.11.5.51' telosb             ---> Builds Wired
#
# I'll leave the wired logic in place in cause we get a USB tag.

COMPONENT=PulseOxApp

USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
USE_WEB=pox.fun

include ../Makerules

# This rather complicated rule says:
#
#   IF  $(PLATFORM) is mwclipboardC,
# THEN  PFLAGS += -DLITE
# ELSE  Require a REGISTRAR to be specified
#
# There is a bug in Gnu Make 3.80 which prevents this from
# being used in a 'ifeq; else; endif' block.

$(if $(filter mwclipboardC,$(PLATFORM)), $(eval PFLAGS += -DLITE), $(call require_REGISTRAR,pulseox))

