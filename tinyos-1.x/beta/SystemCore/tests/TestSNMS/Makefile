COMPONENT=TestSNMS
#SENSORBOARD=micasb

CFLAGS += -DNO_ACK_EST
CFLAGS += -DHELLO_NO_SLEEP

include $(shell ncc -print-tosdir)/../beta/SystemCore/MakeSNMS

include $(TOSDIR)/../apps/Makerules

