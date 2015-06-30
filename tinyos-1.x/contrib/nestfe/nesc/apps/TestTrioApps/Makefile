#COMPONENT=TestSounder
#COMPONENT=TestMag
#COMPONENT=TestPIR
#COMPONENT=TestMic
COMPONENT=TestTrio
#COMPONENT=TestBatt
#COMPONENT=TestGrenade

TRIO_SENSORBOARD=../../sensorboard/trio

include Makerules
PFLAGS += -DOSCOPE_MAX_CHANNELS=8 -I/opt/tinyos-1.x/tos/lib/Oscope -I$(TRIO_SENSORBOARD) 
PLATFORMS=telosb
