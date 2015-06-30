COMPONENT=Nucleus

PFLAGS += -I./include -DDELUGE_GOLDEN_IMAGE
CFLAGS += -DTOSH_MAX_TASKS_LOG2=7 
#CFLAGS += -DDBG_POWERMGMT
#CFLAGS += -DDRIP_NO_SUPPRESS_WAKEUP
#CFLAGS += -DDRIP_SIMPLE_FLOOD

BOOTLOADER = ./bl_xsm.srec

include $(shell ncc -print-tosdir)/../beta/SystemCore/MakeSNMS

include $(TOSDIR)/../apps/Makerules


