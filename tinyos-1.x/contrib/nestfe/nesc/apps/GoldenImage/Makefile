#$Id: Makefile,v 1.9 2005/08/24 18:09:33 gtolle Exp $

COMPONENT = GoldenImage

TOSMAKE_PATH += $(TOSDIR)/../contrib/nestfe/make
TOSMAKE_PATH += $(TOSDIR)/../contrib/nucleus/scripts

GOALS += fileset
GOALS += nucleus
GOALS += supplement

NO_PYTHON=TRUE
NO_RPC=TRUE

CFLAGS += -DDELUGE_NUM_IMAGES=7
CFLAGS += -DTOSH_MAX_TASKS_LOG2=8
CFLAGS += -DNUCLEUS_NO_LEDS

PFLAGS += -I%T/../contrib/nestfe/nesc/lib/kraken
PFLAGS += -I%T/../contrib/nestfe/nesc/lib/cc2420
PFLAGS += -I%T/../contrib/nestfe/nesc/sensorboard/trio

BOOTLOADER ?= $(TOSDIR)/../contrib/nestfe/nesc/tosboot/main.ihex

include $(MAKERULES)

