PFLAGS := $(PFLAGS) -I%T/lib/DiagMsg -I%T/lib/RemoteControl -I%T/lib/FloodRouting
CFLAGS := $(CFLAGS) -DDIAGMSG_BASE_STATION=TOS_UART_ADDR

ifndef COMPONENT
#COMPONENT=RadioCollisionJammerC
COMPONENT=RadioCollisionBaseC
#COMPONENT=RadioCollisionBeaconC
#COMPONENT=RadioCollisionRelayC
endif

include ../Makerules
