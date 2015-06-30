COMPONENT=TestRpcC

GOALS += nescDecls
GOALS += rpc

#GOALS += nucleus
#PFLAGS += -DUSE_NUCLEUS
#TINYOS_NP ?= BNP

PFLAGS += -DTOSH_MAX_TASKS_LOG2=8

CFLAGS += -I$(TOSDIR)/lib/Counters
CFLAGS += -I$(TOSDIR)/lib/Rpc
CFLAGS += -I$(TOSDIR)/lib/RamSymbols
CFLAGS += -I$(TOSDIR)/lib/Registry
CFLAGS += -I$(TOSDIR)/lib/Hood

CFLAGS += -I$(TOSDIR)/lib/Drip
CFLAGS += -I$(TOSDIR)/lib/Drain
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/NucleusExamples

include $(MAKERULES)
