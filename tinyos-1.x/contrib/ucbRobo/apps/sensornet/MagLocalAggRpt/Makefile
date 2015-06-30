##########Generic Stuff##########
ifndef UCBROBODIR
UCBROBODIR := $(shell ncc -print-tosdir)/../contrib/ucbRobo
endif
ifndef CONTRIBDIR
CONTRIBDIR := $(shell ncc -print-tosdir)/../contrib
endif
ifndef MAKERULES
MAKERULES := $(shell ncc -print-tosdir)/../apps/Makerules
endif
#################################


COMPONENT=MagLocalAggRpt
SENSORBOARDS=honeydot


CFLAGS += \
-I$(UCBROBODIR)/include \
-I$(UCBROBODIR)/interfaces \
-I$(UCBROBODIR)/lib/sensornet \
-I$(UCBROBODIR)/lib \
-I$(UCBROBODIR)/lib/sensornet/PEGmagsensor \
-I$(CONTRIBDIR)/ucb/tos/sensorboards/honeydot

#PFLAGS := -I. -Ibuild $(PFLAGS)


include $(MAKERULES)



