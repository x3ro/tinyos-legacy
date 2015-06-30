COMPONENT=TestHoodC


TOSMAKE_PATH += $(TOSDIR)/../contrib/hood/scripts
TOSMAKE_PATH += $(TOSDIR)/../contrib/nucleus/scripts
GOALS += registry
GOALS += hood

ifdef USE_NUCLEUS
GOALS += nucleus
PFLAGS += -DUSE_NUCLEUS
TINYOS_NP ?= BNP
endif

PFLAGS += -DTOSH_MAX_TASKS_LOG2=8

CFLAGS += -I$(TOSDIR)/lib/Counters
CFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Registry
CFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Hood
CFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Rpc

CFLAGS += -I$(TOSDIR)/../beta/Drip
CFLAGS += -I$(TOSDIR)/../beta/Drain
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/NucleusExamples

include $(MAKERULES)

