# When building consider using the following options:
#
#    CURRENT_TIME=`python ./timeSec.py'           Set the time on the clock to current time. no ntp means you need a good starting point
#    BATTERY_VOLTAGE=1		   Pulls in the adc for the Bat voltage but u wont have room
#    
# For example:
#
#    make mwclipboardC16 CURRENT_TIME=`python ./timeSec.py`             ---> Builds NoRadio version for current time


COMPONENT=MenuPulseOxRcvNoRadio

USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
USE_REGISTRAR=clipboard

IP=10.0.0.0
LONG_ADDRESS=0
REGISTRAR=10.0.0.0
PULSEOX=10.0.0.0
IMAP=10.0.0.0

$(warning Define)

ifdef MAILBOX
PFLAGS += -DMAILBOX=\""$(MAILBOX)\""
endif

ifdef HAVE_TELNET
PFLAGS += -DHAVE_TELNET
endif

ifdef CURRENT_TIME
PFLAGS += -DCURRENT_TIME=$(CURRENT_TIME)
endif

PFLAGS += -I../PulseOx 

include ../Makerules

###################################################
# We only verify PULSEOX and IMAP if we're not
# running a 'make clean'
###################################################

ifneq ($(TARGETS),clean)

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

