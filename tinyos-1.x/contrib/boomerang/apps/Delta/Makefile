COMPONENT = Delta
MOTEIV_DIR ?= ../../

ifeq ($(filter lowpower,$(MAKECMDGOALS)),lowpower)
IDENT_PROGRAM_NAME = DeltaLowpower
endif

CFLAGS += -DTOSH_DATA_LENGTH=28+3*2+2 -DMHOP_DEFAULT_QUEUE_SIZE=50

include $(MAKERULES)
