COMPONENT = RssiCollectionC

CFLAGS += -I$(TOSDIR)/lib/Queue
CFLAGS += -I$(TOSDIR)/../contrib/ucb/tos/lib/Straw

#USE_KRAKEN=TRUE

ifndef USE_KRAKEN
GOALS += registry
GOALS += rpc
GOALS += nescDecls
CFLAGS += -I%T/../tos/lib/RamSymbols
CFLAGS += -I%T/../tos/lib/Rpc
CFLAGS += -I%T/../tos/lib/Hood
CFLAGS += -I%T/../tos/lib/Registry
CFLAGS += -I%T/../tos/lib/RegistryStore
CFLAGS += -I%T/../contrib/nucleus/tos/lib/Nucleus
CFLAGS += -I$(TOS2DIR)/chips/stm25p

CFLAGS += -I%T/../beta/Drip
CFLAGS += -I%T/../beta/Drain
include ../../../apps/Makerules
else

PFLAGS += -DUSE_KRAKEN
#NO_LOCATION = TRUE
#NO_TIMESYNC = TRUE
#NO_FILESET = TRUE
#NO_HOOD = TRUE
#NO_REGISTRY = TRUE
#NO_REGISTRY_STORE = TRUE
NO_NUCLEUS = TRUE
#NO_RPC = TRUE
#NO_RPC_FOR_REGISTRY = TRUE
#NO_PYTHON = TRUE
#NO_SENSORS = TRUE
#NO_SUPPLEMENT = TRUE
#NO_UART = TRUE
#NO_PROMETHEUS = TRUE
#NO_DELUGE = TRUE

KRAKEN_MAKERULES ?= $(TOSDIR)/../contrib/nestfe/make/kraken.Makerules
include $(KRAKEN_MAKERULES)
endif
