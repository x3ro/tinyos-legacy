# Top-level Makefile for tools/java 

INITIAL_TARGETS = sim

ROOT = ../../..
include $(ROOT)/Makefile.include

# This depends on SimProtocol being compiled along with the various
# message types from MIG
#NidoSerialDataSource.class: sim

sim: 
	(cd ../sim/msg; $(MAKE))

clean-nido:
	(cd nido; $(MAKE) clean)
