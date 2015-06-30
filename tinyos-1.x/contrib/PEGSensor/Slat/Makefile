COMPONENT=SlatC
IDENT_PROGRAM_NAME=Slat
CONTRIBDIR=../..

ifeq ($(filter mica2dot pc,$(MAKECMDGOALS)),)
SENSORBOARD=micasb
else
SENSORBOARD=honeydot
endif

CFLAGS=-DUART_SYNC

include ../MakePEGSensor

