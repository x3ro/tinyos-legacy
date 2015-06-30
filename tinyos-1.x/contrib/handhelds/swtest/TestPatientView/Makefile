# When building consider using the following options:
#
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address
#    SSID=string                   Set the SSID of the access point
#    IP=x.x.x.x                    Set the IP address of the access point
#    HOST_IP=x.x.x.x   	           Uses wired operation and sets HOST_IP='x.x.x.x'
#    SERVER=x.x.x.x                IP address of the SIPLite server
#    BATTERY_VOLTAGE=1		   Pulls in the adc for the Bat voltage but u wont have room
#    NTP_IP=x.x.x.x.		   Ntp_server, if skipped does a broadcast :)
#    
# For example:
#
#    make LONG_ADDRESS=15 SSID="CRL" IP='16.11.5.30' SERVER='16.11.5.31' telosb       ---> Builds Wireless
#    make HOST_IP='16.11.5.50' IP='16.11.5.51' SERVER='16.11.5.31' telosb             ---> Builds Wired

COMPONENT=TestPatientView
USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
USE_REGISTRAR=pvtest

PFLAGS += -DLITE

include ../Makerules

