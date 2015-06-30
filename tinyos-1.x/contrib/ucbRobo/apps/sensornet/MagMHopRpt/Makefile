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

# Compiles For:
# mica2dot (uses honeydot sensor board) - for the sensor network

COMPONENT=MagMHopRpt
SENSORBOARDS=honeydot

# uses the PEGSensor stack to show how one can choose NOT to use the
# ucbRobo/lib/sensornet/PEGmagsensor stack and still get an
# application compiled.
#
# Alternately, you can use -I$(UCBROBODIR)/lib/sensornet/PEGmagsensor \
# in place of -I$(CONTRIBDIR)/PEGSensor/magsensor \ to use the stack in
# ucbRobo.  Of course, due to file renaming, you'll have to 'include
# MagSensorTypes' instead of 'include MagSensor' in some of your
# files... this should be a good exercise for the user.
CFLAGS += \
-I$(UCBROBODIR)/include \
-I$(UCBROBODIR)/interfaces \
-I$(UCBROBODIR)/lib/sensornet \
-I$(UCBROBODIR)/lib \
-I$(CONTRIBDIR)/PEGSensor/magsensor \
-I$(CONTRIBDIR)/ucb/tos/sensorboards/honeydot \
-I%T/lib/MintRoute \
-I%T/lib/Broadcast \
-I%T/lib/Queue

# for this application, 
# -I$(CONTRIBDIR)/SystemC/common \
# is interchangeable with :
# -I$(UCBROBODIR)/interfaces \
# -I$(UCBROBODIR)/lib/sensornet \
# -I$(UCBROBODIR)/lib \
# and it will still compile

include $(MAKERULES)


