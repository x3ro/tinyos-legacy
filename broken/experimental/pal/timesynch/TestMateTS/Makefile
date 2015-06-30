COMPONENT        = TestMateTS
VU               = /root/src/tinyos-1.x/contrib/vu
BUILD_EXTRA_DEPS = TimeTestMsg.class
CONSTANTS        = -DTIMESYNC_RATE=60 -DCC1K_DEFAULT_FREQ=CC1K_915_998_MHZ


#PFLAGS += -I%T/lib/VM/types -I%T/lib/VM/interfaces -I. -I$(VU)/tos/lib/TimeSync

PFLAGS += -I/root/src/broken/experimental/pal/timesynch/contexts -I$(VU)/tos/lib/TimeSync  -I%T/lib/VM/types -I%T/lib/VM/interfaces -I. -I$(VU)/tos/system -I$(VU)/packages/30msTS $(CONSTANTS)


include ../Makerules

TimeTestMsg.java:
	mig java $(CFLAGS) $(PFLAGS) -java-classname=TimeTestMsg TimeTest.h TimeTestMsg -o $@ 

%.class: %.java
	javac $<
