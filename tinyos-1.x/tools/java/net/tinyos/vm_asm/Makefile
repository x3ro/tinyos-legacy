
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.vm_asm
MIG = mig java

# List of message classes to build
MSGS = BombillaErrorMsg.java BombillaCapsuleMsg.java BombillaDataMsg.java BombillaConstants.java MateConstants.java

INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include
MATE=$(TOS)/lib/VM
APP=$(TOS)/../apps/Bombilla
NCG = ncg java

BINCLUDES=-I$(APP)/ -I$(MATE)/components -I$(TOS)/lib/VM/interfaces -I$(MATE)/types -I$(MATE)/contexts -I$(MATE)/opcodes -I$(TOS)/lib/Route -I$(TOS)/lib/Queue -I$(TOS)/sensorboards/micasb

MINCLUDES=-I$(APP)


BombillaErrorMsg.java:
	$(MIG) $(MINCLUDES) -java-classname=$(PACKAGE).BombillaErrorMsg $(MATE)/types/Bombilla.h BombillaErrorMsg -o $@

BombillaCapsuleMsg.java:
	$(MIG)  $(MINCLUDES) -java-classname=$(PACKAGE).BombillaCapsuleMsg $(MATE)/types/Bombilla.h BombillaCapsuleMsg -o $@

BombillaDataMsg.java:
	$(MIG)  $(MINCLUDES) -java-classname=$(PACKAGE).BombillaDataMsg $(MATE)/types/Bombilla.h BombillaPacketMsg -o $@

BombillaConstants.java: 
	$(NCG) $(BINCLUDES) -java-classname=$(PACKAGE).BombillaConstants $(APP)/AbstractMate.nc AbstractConstants.h  -o$@

MateConstants.java:
	$(NCG) $(BINCLUDES) -java-classname=$(PACKAGE).MateConstants $(APP)/AbstractMate.nc Bombilla.h  -o$@

cleanmig:
	rm -f $(MSGS)

