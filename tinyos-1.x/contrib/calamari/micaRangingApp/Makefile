COMPONENT=TransceiverApp
DEFAULT_LOCAL_GROUP=0xdd
CFLAGS=-DUART_SYNC
CONTRIBDIR=../..

ifndef TOSROOT
TOSROOT := $(shell ncc -print-tosdir)/../
endif
CFLAGS := $(CFLAGS) \
-I$(TOSDIR)/lib/DiagMsg \
-I$(TOSROOT)/beta/I2C/system \
-I$(TOSROOT)/beta/I2C/platform/mica2dot \
-I$(TOSROOT)/beta/I2C/platform/mica2 \
-I$(TOSROOT)/beta/I2C/platform/mica \
-I$(TOSROOT)/beta/I2C/platform/avrmote \
-I$(TOSROOT)/beta/I2C/types \
-I$(TOSROOT)/beta/I2C/interfaces 

include ../MakeCalamari

