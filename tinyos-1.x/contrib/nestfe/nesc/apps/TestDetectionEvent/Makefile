COMPONENT = TestDetectionEventC

PFLAGS += -I$(TOSDIR)/../contrib/nestfe/nesc/lib/Metrics
PFLAGS += -I$(TOSDIR)/lib/Queue
PFLAGS += -I$(TOSDIR)/lib/Broadcast
PFLAGS += -I$(TOSDIR)/../contrib/nestfe/nesc/lib/Straw

#PFLAGS += -DRPC_LEDS

#Used by event generators in detectionevent
PFLAGS += -DNO_LEDS

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

