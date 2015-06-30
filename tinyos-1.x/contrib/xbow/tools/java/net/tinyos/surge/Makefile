# Top-level Makefile for tools/java 

SUBDIRS = event util PacketAnalyzer Dialog stats messages

INITIAL_TARGETS = messages

TOS = ../../../../../../..
PACKAGE = net.tinyos.surge
MIG = mig java

ROOT = ../../../../../../../tools/java
include $(ROOT)/Makefile.include

messages:
	cd messages; make