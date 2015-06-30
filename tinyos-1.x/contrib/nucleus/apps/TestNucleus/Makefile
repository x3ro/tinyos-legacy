COMPONENT=TestNucleus

TOSMAKE_PATH += $(TOSDIR)/../contrib/nucleus/scripts

CFLAGS += -DTOSH_MAX_TASKS_LOG2=8

CFLAGS += -I$(TOSDIR)/../beta/Drip
CFLAGS += -I$(TOSDIR)/../beta/Drain
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/Nucleus
CFLAGS += -I$(TOSDIR)/../contrib/nucleus/tos/lib/NucleusExamples

#PFLAGS += -DNUCLEUS_NO_EVENTS

include $(TOSDIR)/../apps/Makerules
