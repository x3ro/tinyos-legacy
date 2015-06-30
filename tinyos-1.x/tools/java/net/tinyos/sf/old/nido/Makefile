# Top-level Makefile for tools/java 

SUBDIRS = 
INITIAL_TARGETS = sim

ROOT = ../../../../..
include $(ROOT)/Makefile.include

# This depends on SimProtocol being compiled along with the various
# message types from MIG
NidoSerialDataSource.class: sim

SimNetworkDataSource.class: sim

sim: 
	(cd ../../../sim/msg; $(MAKE))
