# Top-level Makefile for tools/java 


TOS = $(shell ncc -print-tosdir)
PACKAGE = com.shockfish.tinyos.apps.demo
APP = ${TOSROOT}/apps/Oscilloscope
MIG = mig  -target=tinynode -I ${TOSROOT}/contrib/shockfish/tos/platform/tinynode java

MSGS = OscopeMsg.java

all: cleanmig ${MSGS}


INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

OscopeMsg.java:
	$(MIG) -v -java-classname=$(PACKAGE).OscopeMsg ${APP}/OscopeMsg.h OscopeMsg -o $@

cleanmig:
	rm -f $(MSGS)
	

TOS = $(shell ncc -print-tosdir)
ROOT = $(TOS)/../tools/java


include $(ROOT)/Makefile.include
	
