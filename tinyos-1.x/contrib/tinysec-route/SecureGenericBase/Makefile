               #adds UART synchronization before each packet
CFLAGS := $(CFLAGS) -DUART_SYNC \
	-I../routeinterpret \
	-I../../PEGSensor/PEGSensor

SENSORBOARDS=
TINYSEC=true
DEFAULT_LOCAL_GROUP=0xdd
CONTRIBDIR=../..
COMPONENT=GenericBase
include ../MakeTinySec
