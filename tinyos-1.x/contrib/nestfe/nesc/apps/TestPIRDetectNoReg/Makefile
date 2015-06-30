#COMPONENT=TestPIRDetectSimple
COMPONENT=TestPIRDetect
PFLAGS += -I%T/../contrib/nestfe/nesc/lib/PIRDetect

ifneq ($(findstring pc,$(MAKECMDGOALS)),)
# see SimHelp/README.SimHelp
PFLAGS += -I%T/../contrib/nestfe/nesc/apps/TestPIRDetectNoReg/SimHelp
ifneq ($(findstring sim,telos,$(MAKECMDGOALS)),)
## default: make pc
else
## make pc sim,telos
PFLAGS += -I%T/../beta/TOSSIM-packet
endif
else
## make telosb (or others)
# make sure we do not pull the wrong sensorboard.h for simulation
PFLAGS += -I%T/../contrib/nestfe/nesc/sensorboard/trio
endif

PFLAGS += -I%T/lib/Oscope -DOSCOPE_MAX_CHANNELS=8

DEFfAULT_LOCAL_GROUP ?= 0x7d
include $(shell ncc -print-tosdir)/../apps/Makerules
