COMPONENT=TestStraw

PLATFORMS=mica2 micaz
PLATFORM := $(filter mica2 micaz, $(MAKECMDGOALS))

ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif

PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Queue
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Broadcast
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/MintRoute
PFLAGS += -I$(CONTRIBDIR)/GGB/tos/lib/Straw

include ../Makerules
