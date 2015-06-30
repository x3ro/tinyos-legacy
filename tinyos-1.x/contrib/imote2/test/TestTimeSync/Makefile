################################################################################
# supported platforms:  mica2, 
#                       mica2dot, 
#                       micaZ (only TIMESYNC_SYSTIME), 
#                       telos
#
# the following directives are recognized by TimeSync component 
#
# -DTIMESYNC_DEBUG: enforces multiple hops in software
# -DTIMESYNC_SYSTIME: choice of clock source(1MHz internal, or 32kHz external)
#
################################################################################

#period of timesync msg broadcast and the period of reference broadcast
PFLAGS += -DTIMESYNC_RATE=30 -DTIMESYNC_POLLER_RATE=10 -DTIMESYNC_SYSTIME
PFLAGS += -DPLATFORM_IMOTE2
# -DTIMESYNC_DIAG_POLLER: response to poller is diag msg, otherwise regular msg
# warning! DiagMsgC does not work corretctly for telos platform!
ifdef TIMESYNC_DIAG_POLLER
    PFLAGS += -I%T/lib/DiagMsg -DTIMESYNC_DIAG_POLLER
endif

#path to the vanderbilt TimeSync component
#PFLAGS += -I%T/lib/TimeSync 
PFLAGS += -I../../tos/lib/TimeSync -I../../tos/interfaces

############################ SPECIFY COMPONENT FILE ###########################
ifdef POLLER
	COMPONENT=TestTimeSyncPollerC
else
	COMPONENT=TestTimeSyncC
endif

include ../Makerules

