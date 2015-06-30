# When building consider using the following options:
#
#    LONG_ADDRESS=number           Set the bottom 2 bytes of the long MAC address
#    SSID=string                   Set the SSID of the access point
#    IP=x.x.x.x                    Set the IP address of the access point
#    HOST_IP=x.x.x.x   	           Uses wired operation and sets HOST_IP='x.x.x.x'
#    SERVER=x.x.x.x                IP address of the SIPLite server
#    BATTERY_VOLTAGE=1		   Pulls in the adc for the Bat voltage but u wont have room
#    HAVE_TELNET=1		   Pulls in the Telnet server
#    NTP_IP=x.x.x.x.		   Ntp_server, if skipped does a broadcast 
#    IMAP_SERVER=x.x.x.x
#    REGISTRAR_IP=x.x.x.x
#    
# For example:
#
#    make LONG_ADDRESS=15 SSID="CRL" IP='16.11.5.30' SERVER='16.11.5.31' telosb       ---> Builds Wireless
#    make HOST_IP='16.11.5.50' IP='16.11.5.51' SERVER='16.11.5.31' telosb             ---> Builds Wired
#
# I'll leave the wired logic in place in cause we get a USB tag.

COMPONENT=MenuPulseOxRcv

USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
USE_REGISTRAR=clipboard

ifdef MAILBOX
PFLAGS += -DMAILBOX=\""$(MAILBOX)\""
endif

ifdef HAVE_TELNET
PFLAGS += -DHAVE_TELNET
endif

ifdef BATTERY_VOLTAGE
PFLAGS += -DBATTERY_VOLTAGE
endif

PFLAGS += -I../PulseOx 

include ../Makerules

###################################################
# We only verify PULSEOX and IMAP if we're not
# running a 'make clean'
###################################################

ifneq ($(TARGETS:clean%=clean),clean)

ifeq (,$(findstring mwclipboard,$(PLATFORM)))
$(error You must specify a clipboard build type).
endif

ifdef PULSEOX
ifneq ($(PULSEOX)_x, off_x)
PFLAGS += -DSERVER="$(shell echo $(PULSEOX) | sed -e 's/\./,/g')"
endif
else
$(error You must specify a PULSEOX ip address.)
endif

ifdef IMAP
PFLAGS += -DIMAP_SERVER="$(shell echo $(IMAP) | sed -e 's/\./,/g')"
else
$(error You must specify an IMAP server.)
endif

endif # ($(TARGETS),clean)

