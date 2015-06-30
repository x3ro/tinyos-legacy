COMPONENT ?= GlowLightC
CFLAGS += -DOSCOPE_MAX_CHANNELS=3
CFLAGS += -DSEND_TO_UART
PFLAGS += -I$./
PFLAGS += -I$(TOSDIR)/../contrib/shockfish/tos/lib/OscopeUART
PFLAGS += -I$(TOSDIR)/lib/Oscope
PFLAGS += -I$(TOSDIR)/../contrib/shockfish/tos/sensorboards/extboard/
CFLAGS += -I%T/lib/LedsIntensity
include $(MAKERULES)

