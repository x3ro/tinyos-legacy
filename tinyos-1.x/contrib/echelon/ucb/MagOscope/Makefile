COMPONENT = MagOscopeC

CONTRIBDIR ?= $(TOSDIR)/../contrib
APPSDIR ?= $(TOSDIR)/../apps

CFLAGS += \
-I$(APPSDIR)/Oscilloscope \
-I$(CONTRIBDIR)/PEGSensor/magsensor \
-I$(CONTRIBDIR)/SystemC/common

PFLAGS := -I. -Ibuild $(PFLAGS)
#PFLAGS += -DCC1K_DEF_FREQ=430000000

include ../../Makerules

