COMPONENT = TSyncAppC

CFLAGS += -DTIMESYNC_RATE=30
CFLAGS += -DPI_MICRO

#enable protocol
PFLAGS += -I../FloodPISync/
#PFLAGS += -I../AvgPISync/

BUILD_EXTRA_DEPS = TSyncAppMsg.class
CLEAN_EXTRA = *.class TSyncAppMsg.java

TSyncAppMsg.class: TSyncAppMsg.java
	javac *.java
	
TSyncAppMsg.java: TSyncApp.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TSyncAppMsg TSyncApp.h TSyncAppMsg_t -o $@
	
include $(MAKERULES)