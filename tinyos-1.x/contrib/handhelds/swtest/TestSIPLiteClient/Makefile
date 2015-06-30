# When building consider using the following options:
#
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address
#    SSID=string                   Set the SSID of the access point
#    IP=x.x.x.x                    Set the IP address of the access point
#    HOST_IP=x.x.x.x   	           Uses wired operation and sets HOST_IP='x.x.x.x'
#    SERVER=x.x.x.x                IP address of the SIPLite server
#    
# For example:
#
#    make LONG_ADDRESS=15 SSID="CRL" IP='16.11.5.30' SERVER='16.11.5.31' telosb       ---> Builds Wireless
#    make HOST_IP='16.11.5.50' IP='16.11.5.51' SERVER='16.11.5.31' telosb             ---> Builds Wired

COMPONENT=TestSIPLiteClient
USE_IP=True
SELECT_WIRED_OR_WIRELESS=True

include ../Makerules

###################################################
# We only verify IMAP if we're not
# running a 'make clean'
###################################################

ifneq ($(TARGETS:clean%=clean),clean)

ifdef SERVER
PFLAGS += -DSIPLITE_SERVER="$(shell echo $(SERVER) | sed -e 's/\./,/g')"
else
$(error You must specify a SIPLite SERVER server (e.g. SERVER=10.1.1.1))
endif

endif # ($(TARGETS),clean)

