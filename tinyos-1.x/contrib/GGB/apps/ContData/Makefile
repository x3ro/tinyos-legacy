COMPONENT=ContSense
SENSORBOARD=ggbacltst
PLATFORMS=mica2 micaz
PLATFORM := $(filter mica2 micaz, $(MAKECMDGOALS))

ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif

CFLAGS += -I$(CONTRIBDIR)/GGB/tos/sensorboards/ggbacltst

DEFAULT_LOCAL_GROUP := 0xCA
ifeq ($(PLATFORM),mica2)
PFLAGS += -DCC1K_DEF_FREQ=432080400
#CFLAGS += -DRADIO_XMIT_POWER=0x01
endif
ifeq ($(PLATFORM),micaz)
PFLAGS += -DCC2420_DEF_CHANNEL=0x15
#PFLAGS += -DCC2420_DEF_RFPOWER=0x01
endif

include ../Makerules

