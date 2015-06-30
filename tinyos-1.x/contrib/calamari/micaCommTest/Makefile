COMPONENT=MicaCommTestC
CFLAGS=-DUART_SYNC
DEFAULT_LOCAL_GROUP=0xdd
CONTRIBDIR=../..

ifndef TOSROOT
TOSROOT := $(shell ncc -print-tosdir)/../
endif
CFLAGS := $(CFLAGS) \
-I$(TOSROOT)/beta/I2C/system \
-I$(TOSROOT)/beta/I2C/platform/mica2dot \
-I$(TOSROOT)/beta/I2C/platform/mica2 \
-I$(TOSROOT)/beta/I2C/platform/mica \
-I$(TOSROOT)/beta/I2C/platform/avrmote \
-I$(TOSROOT)/beta/I2C/types \
-I$(TOSROOT)/beta/I2C/interfaces 

include ../MakeCalamari

