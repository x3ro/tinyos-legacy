##########Generic Stuff##########
ifndef UCBROBODIR
UCBROBODIR := $(shell ncc -print-tosdir)/../contrib/ucbRobo
endif
ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif
ifndef COSTBOTSDIR
COTSBOTSDIR := $(shell ncc -print-tosdir)/../contrib/cotsbots
endif
ifndef MAKERULES
MAKERULES := $(shell ncc -print-tosdir)/../apps/Makerules
endif
#################################


COMPONENT=SenseAndNavigate
CFLAGS += \
-I$(COTSBOTSDIR)/tos/platform/%p \
-I$(COTSBOTSDIR)/tos/interfaces \
-I$(COTSBOTSDIR)/tos/system \
-I$(COTSBOTSDIR)/tos/lib

include $(MAKERULES)


