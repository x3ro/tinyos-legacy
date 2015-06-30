#

COMPONENT=TestIR

ifdef IP
USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
endif

include ../Makerules

ifdef BAUDRATE
PFLAGS += -DIR_BAUDRATE=$(BAUDRATE)
endif
