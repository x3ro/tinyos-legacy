COMPONENT=PWMRadioReceiveC
PFLAGS =-I../include -I../../TelosPWM/
include $(MAKERULES)

mig-message:
	mig -java-classname=PWMMessage java ../include/PWMMessage.h PWMMsg -o PWMMessage.java

