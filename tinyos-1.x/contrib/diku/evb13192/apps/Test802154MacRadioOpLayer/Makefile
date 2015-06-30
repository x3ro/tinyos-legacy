
# TinyOS 802.15.4 stack.
COMPONENT=Test802154MacRadioOpLayer
ENVIRONMENT=Generic802154
#CHC08_OPTS=-TE4uE -F2 -Lp -Cs08
PFLAGS=-I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154 \
       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/phy \
       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac \
       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac/ADTModules \
       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac/interfaces
NESC_FLAGS=-Wno-nesc-data-race -Wnesc-async -Wno-nesc-fnptr -Wnesc-combine

include ../Makerules
