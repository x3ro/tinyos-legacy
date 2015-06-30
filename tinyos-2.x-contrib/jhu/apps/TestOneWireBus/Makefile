COMPONENT=TestC

CONTRIB_ROOT?=/home/carlson/tinyos-2.x-contrib/jhu

CFLAGS+=-DMAX_ONEWIRE_DEVICES=2

CFLAGS += -IdummyOW
CFLAGS += -I$(CONTRIB_ROOT)/tos/lib/onewire
CFLAGS += -I$(CONTRIB_ROOT)/tos/lib/onewire/interfaces
CFLAGS += -I$(CONTRIB_ROOT)/tos/chips/ds1825


#In general, this should be included automatically by modifying the
# appropriate .platform file.  it's included this way to make this
# component work within tinyos-contrib
PFLAGS += -I$(CONTRIB_ROOT)/tos/platforms/telosb
PFLAGS += -I$(CONTRIB_ROOT)/tos/platforms/telosb/hardware/onewire

PFLAGS += -I$(TOSDIR)/lib/printf

include $(MAKERULES)
