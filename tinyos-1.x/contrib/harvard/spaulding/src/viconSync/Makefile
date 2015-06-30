COMPONENT = ViconSyncC

include $(SPAULDINGSRC)/Makefile.in
include $(SPAULDINGSRC)/timeSync/Makefile.in
PFLAGS += -I$(SPAULDINGSRC)/lib/

# FTSP - HACK, these should not be here.  For now, MUST match Driver Makefile
PFLAGS += -DFTSP_ENTRY_THROWOUT_LIMIT=100
PFLAGS += -DFTSP_STATIC_ROOT_ID=10
PFLAGS += -DFTSP_TIMESYNC_RATE=2   # how often beacons are sent [sec]

#PFLAGS += -DPRINTFUART_ENABLED

include $(MAKERULES)
