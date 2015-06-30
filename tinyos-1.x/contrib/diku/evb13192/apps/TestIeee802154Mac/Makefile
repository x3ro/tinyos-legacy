MAC_TYPE=Generic

ifeq ($(MAC_TYPE),Generic)
	# TinyOS 802.15.4 stack.
	COMPONENT=TestIeee802154Mac
	ENVIRONMENT=Generic802154
	PFLAGS=-I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154 \
	       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac \
	       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac/ADTModules \
	       -I$(TINYOS_EVB13192DIR)/tos/lib/ieee802154/mac/interfaces
	NESC_FLAGS=-Wno-nesc-data-race -Wnesc-async -Wno-nesc-fnptr -Wnesc-combine
endif
ifeq ($(MAC_TYPE),Freescale)
	# Freescale 802.15.4 stack.
	COMPONENT=TestFreescale802154Mac
	ENVIRONMENT=FFD
	PFLAGS=-I$(TINYOS_EVB13192DIR)/tos/lib/freescale802154
endif

include ../Makerules
