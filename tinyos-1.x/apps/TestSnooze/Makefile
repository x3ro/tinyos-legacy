PLATFORMS=mica mica2 mica2dot

PLATFORM := $(filter mica mica2 mica2dot, $(MAKECMDGOALS))

ifeq ($(PLATFORM),mica)
	COMPONENT=TestSnooze
endif
ifeq ($(PLATFORM),mica2)
	CFLAGS+=-I$(TOSDIR)/lib/OnOff
	COMPONENT=OnOffApp
endif
ifeq ($(PLATFORM),mica2dot)
        CFLAGS+=-I$(TOSDIR)/lib/OnOff
	COMPONENT=OnOffApp
endif		
include ../Makerules

