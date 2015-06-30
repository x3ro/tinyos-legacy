COMPONENT=AbstractMate
CFLAGS=-I%T/../beta/TOSSIM-packet -I/root/src/tinyos-1.x/tos/lib/VM/opcodes -I/root/src/tinyos-1.x/tos/lib/VM/contexts -I/root/src/tinyos-1.x/tos/lib/VM/languages -I/root/src/tinyos-1.x/tos/sensorboards/micasb  -I%T/lib/VM/components -I%T/lib/VM/opcodes -I%T/lib/VM/contexts -I%T/lib/VM/types -I%T/lib/VM/interfaces -I%T/lib/Queue -I%T/lib/VM/route -I.
MSG_SIZE=36
BUILD_EXTRA_DEPS=FirecrackerVMConstants.class CapsuleMsg.class

include ../Makerules

FirecrackerVMConstants.java:
	ncg java $(CFLAGS) -java-classname=FirecrackerVMConstants AbstractMate.nc AbstractConstants.h -o$@

CapsuleMsg.java:
	mig java $(CFLAGS) -java-classname=CapsuleMsg ../../tos/lib/VM/types/Bombilla.h BombillaCapsuleMsg -o $@

%.class: %.java
	javac $<
cleanmig:
	rm -f FirecrackerVMConstants.*

clean: cleanmig
	rm -rf build/
	rm -f core.*
	rm -f *~
