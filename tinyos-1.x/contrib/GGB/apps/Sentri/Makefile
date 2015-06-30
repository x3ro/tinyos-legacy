COMPONENT=DataCollector

PLATFORMS=mica2 micaz
PLATFORM := $(filter mica2 micaz, $(MAKECMDGOALS))
SENSORBOARD=ggbacltst

ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif


PFLAGS += -I$(CONTRIBDIR)/GGB/tos/sensorboards/ggbacltst

PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Queue
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Broadcast
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/MintRoute
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Straw

PFLAGS += -I$(CONTRIBDIR)/vu/tos/interface
PFLAGS += -I$(CONTRIBDIR)/vu/tos/lib/TimeSync
ifeq ($(PLATFORM),micaz)
PFLAGS += -I$(CONTRIBDIR)/vu/tos/lib/CC2420
endif
#PFLAGS += -I$(CONTRIBDIR)/vu/tos/platform/avrmote
PFLAGS += -I$(CONTRIBDIR)/vu/tos/platform/mica2
PFLAGS += -DTIMESYNC_RATE=10
PFLAGS += -DTIMESYNC_SYSTIME


DEFAULT_LOCAL_GROUP := 0xCA
ifeq ($(PLATFORM),mica2)
PFLAGS += -DCC1K_DEF_FREQ=432080400
CFLAGS += -DRADIO_XMIT_POWER=0xFF
endif
ifeq ($(PLATFORM),micaz)
PFLAGS += -DCC2420_DEF_CHANNEL=0x15
#PFLAGS += -DCC2420_DEF_RFPOWER=0x02
endif

include ../Makerules

