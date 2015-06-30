COMPONENT=PEGSensorC
IDENT_PROGRAM_NAME="PEG"
CONTRIBDIR=../..

ifeq ($(filter mica2dot pc,$(MAKECMDGOALS)),)
SENSORBOARDS=micasb
else
SENSORBOARDS=honeydot omnisound
endif

CFLAGS=-DUART_SYNC

include ../MakePEGSensor

