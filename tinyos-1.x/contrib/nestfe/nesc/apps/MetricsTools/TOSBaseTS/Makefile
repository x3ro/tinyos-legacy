COMPONENT=TOSBase
CFLAGS += -DTOSH_MAX_TASKS_LOG2=8

#CC2420_CHANNEL := 0x0b
#DEFAULT_LOCAL_GROUP := 0x23
CC2420_CHANNEL := 0x12
DEFAULT_LOCAL_GROUP := 0x0b
## Recognized Msg Types for Timestamping
PFLAGS += -I$(TOSDIR)/../contrib/nestfe/nesc/lib/Metrics
PFLAGS += -I$(TOSDIR)/lib/Drain

include $(TOSDIR)/../apps/Makerules
