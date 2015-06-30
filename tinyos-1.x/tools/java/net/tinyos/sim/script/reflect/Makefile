# Makefile for tools/java/net/tinyos/sim/script/reflect

ROOT = ../../../../..
include $(ROOT)/Makefile.include

DOCS := 	Commands.java \
		Interp.java \
		Mote.java \
		Packets.java \
		Radio.java \
		Random.java \
		Sensor.java \
		Sim.java \
		SimObject.java

DOCS := $(patsubst %,../../../tools/java/net/tinyos/sim/script/reflect/%, \
		$(DOCS))

javadoc:
	cd $(ROOT)/../../doc/tython/javadoc && \
		javadoc -public -breakiterator -notree $(DOCS)
