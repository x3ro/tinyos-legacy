COMPONENT=TOSBaseGPRS
SENSORBOARD = mamaboard
CFLAGS += -DTOSH_MAX_TASKS_LOG2=8

ifeq ($(SENSORBOARD),mamaboard)
 PFLAGS += -DMAMABOARD
 PFLAGS += -I$(TOSDIR)/../contrib/shockfish/tos/sensorboards/mamaboard/
endif
include $(MAKERULES)
