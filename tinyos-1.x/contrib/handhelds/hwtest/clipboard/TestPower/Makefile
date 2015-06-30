# Test power configurations

COMPONENT=TestPower

ifdef RADIO
USE_RADIO=True
PFLAGS += -DRADIO
endif

ifdef IR
PFLAGS += -DIR
endif

ifdef IRDA
PFLAGS += -DIRDA
endif

ifdef MSP
PFLAGS += -DMSP
endif

ifdef LCD_LINES
PFLAGS += -DLCD_LINES=${LCD_LINES}
endif

ifdef BACKLIGHT
PFLAGS += -DBACKLIGHT
endif

include ../../Makerules

