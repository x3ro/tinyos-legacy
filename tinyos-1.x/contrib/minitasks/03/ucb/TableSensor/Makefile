COMPONENT=TableSensorC
IDENT_PROGRAM_NAME="Table"

ifeq ($(filter mica2dot pc,$(MAKECMDGOALS)),)
SENSORBOARDS=micasb
else
SENSORBOARDS=honeydot
endif

CFLAGS=-DUART_SYNC
USER_INCLUDES=-I../PEGSensor -I../croute -I../routetest2 -I../position -I../../../02/vu/tos/lib/DiagMsg -I../pursuer

include ../Makerules

