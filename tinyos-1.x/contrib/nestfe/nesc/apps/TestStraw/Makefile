COMPONENT=TestStraw

PFLAGS += -I$(TOSDIR)/lib/Queue
PFLAGS += -I$(TOSDIR)/../beta/Drip
PFLAGS += -I$(TOSDIR)/../beta/Drain
PFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
PFLAGS += -I$(TOSDIR)/../../tinyos-2.x/tos/chips/stm25p
PFLAGS += -I$(TOSDIR)/../contrib/nestfe/nesc/lib/Straw

NO_LOCATION = TRUE
NO_TIMESYNC = TRUE
#NO_FILESET = TRUE
NO_HOOD = TRUE
NO_REGISTRY = TRUE
NO_REGISTRY_STORE = TRUE
NO_NUCLEUS = TRUE
NO_RPC = TRUE
NO_RPC_FOR_REGISTRY = TRUE
NO_PYTHON = TRUE
#NO_SENSORS = TRUE
#NO_SUPPLEMENT = TRUE
#NO_UART = TRUE
#NO_PROMETHEUS = TRUE
#NO_DELUGE = TRUE

#PLATFORM=pc

#PFLAGS += -DRPC_LEDS


DEFAULT_LOCAL_GROUP := 0x0C
PFLAGS += -DCC2420_DEF_CHANNEL=0x13


KRAKEN_MAKERULES ?= $(TOSDIR)/../contrib/nestfe/make/kraken.Makerules
include $(KRAKEN_MAKERULES)

