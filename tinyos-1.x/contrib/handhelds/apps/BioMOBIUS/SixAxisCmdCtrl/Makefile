COMPONENT=SixAxisCmdCtrl

include ../../Makerules

#PFLAGS += -DLOW_BATTERY_INDICATION

ifndef USE_ID_CHIP
$(error You can only build this against a platform that has an ID chip)
else
PFLAGS += -DID_CHIP=$(USE_ID_CHIP)
ifdef HAS_ID_CHIP_POWER
PFLAGS += -DID_CHIP_POWER
endif
endif
