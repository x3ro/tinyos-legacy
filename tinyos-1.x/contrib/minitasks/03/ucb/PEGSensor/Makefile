COMPONENT=PEGSensorC
IDENT_PROGRAM_NAME="PEG"

ifeq ($(filter mica2dot pc,$(MAKECMDGOALS)),)
SENSORBOARDS=micasb
else
SENSORBOARDS=honeydot omnisound
endif

CFLAGS=-DUART_SYNC
USER_INCLUDES=\
-I../croute \
-I../routetest2 \
-I../UltrasonicRanging \
-I$(TOSDIR)/lib/UltrasonicRanging \
-I$(TOSDIR)/lib/UltrasonicRanging/HPLUART \
-I../position \
-I../../../02/vu/tos/lib/DiagMsg \
-I../pursuer

USER_INCLUDES=\
-I../croute \
-I../routetest2 \
-I../UltrasonicRanging \
-I../position \
-I../../../02/vu/tos/lib/DiagMsg \
-I../pursuer

include ../Makerules

