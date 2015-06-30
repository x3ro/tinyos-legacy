COMPONENT=TOSBase

ifndef BETADIR
BETADIR := $(shell ncc -print-tosdir)/../beta
endif

CFLAGS += -I$(BETADIR)/SystemCore/CC1000

include $(TOSDIR)/../apps/Makerules

