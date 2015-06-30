COMPONENT=CalamariC


TOSMAKE_PATH += $(TOSDIR)/../contrib/hood/scripts
TOSMAKE_PATH += $(TOSDIR)/../contrib/nucleus/scripts
GOALS += registry
GOALS += hood
GOALS += rpc

#ifdef USE_NUCLEUS
GOALS += nucleus
PFLAGS += -DUSE_NUCLEUS
TINYOS_NP ?= BNP
#endif

PFLAGS += -DTOSH_MAX_TASKS_LOG2=8

PFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Registry
PFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Hood
PFLAGS += -I$(TOSDIR)/../contrib/hood/tos/lib/Rpc

PFLAGS += -I$(TOSDIR)/../beta/Drip
PFLAGS += -I$(TOSDIR)/../beta/Drain
PFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
PFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/NucleusExamples

include $(MAKERULES)

