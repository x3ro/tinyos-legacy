COMPONENT=CalamariC
SENSORBOARD := micasb
PROGRAMMER_EXTRA_FLAGS := -dlpt=3
USER_INCLUDES = \
-I$(TOSDIR)/sensorboards/micasb 
CFLAGS=-DUART_SYNC

DEFAULT_LOCAL_GROUP=0xcc

include ../Makerules
ifeq ($(PLATFORM),pc)
   PFLAGS:= $(PFLAGS) -DMAKEPC=1
endif


#-I../../../02/vu/tos/lib/AcousticRanging \
#-I../../../02/vu/tos/system \
#-I../../../02/vu/tos/lib/BigMsg \
#-I../../../02/vu/tos/lib/DiagMsg \
#-I../../../02/vu/tos/lib/TimeSync \
#-I../../../02/vu/tos/lib/ZeroCrossings \
#-I../../../02/vu/tos/platform/mica2 \
#-I../../../02/vu/tos/platform/avrmote 
