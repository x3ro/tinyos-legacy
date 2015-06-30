COMPONENT=TOSBase
CFLAGS += -DTOSH_MAX_TASKS_LOG2=8
CFLAGS += -DDRAIN_ENDPOINT_ONLY

TOSMAKE_PATH += $(TOSDIR)/../contrib/nucleus/scripts

CFLAGS += -I$(TOSDIR)/../beta/Drip
CFLAGS += -I$(TOSDIR)/../beta/Drain
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/NucleusExamples

include $(TOSDIR)/../apps/Makerules

