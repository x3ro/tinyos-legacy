COMPONENT=MagOscopeC
SENSORBOARDS=honeydot

ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif

ifndef APPSDIR
APPSDIR := $(shell ncc -print-tosdir)/../apps
endif

CFLAGS += \
-I$(APPSDIR)/Oscilloscope \
-I$(CONTRIBDIR)/PEGSensor/magsensor \
-I$(CONTRIBDIR)/SystemC/common \
-I$(CONTRIBDIR)/ucb/tos/sensorboards/honeydot


PFLAGS := -I. -Ibuild $(PFLAGS)
#PFLAGS += -DCC1K_DEFAULT_FREQ=CC1K_434_845_MHZ
PFLAGS += -DCC1K_DEF_FREQ=430000000

ifndef MAKERULES
MAKERULES := $(shell ncc -print-tosdir)/../apps/Makerules
endif

include $(MAKERULES)

