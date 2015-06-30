COMPONENT=LocalizationAppC
DEFAULT_LOCAL_GROUP=0xdd
ifeq ($(filter mica2dot pc,$(MAKECMDGOALS)),)
SENSORBOARDS=micasb
else
SENSORBOARDS=honeydot
endif

CFLAGS=-DUART_SYNC
USER_INCLUDES=-I../croute -I../routetest2 -I../UltrasonicRanging -I$(TOSDIR)/lib/UltrasonicRanging -I$(TOSDIR)/lib/UltrasonicRanging/HPLUART -I../position -I../../DiagMsg -I../pursuer

include ../Makerules

