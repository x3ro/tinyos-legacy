# Top-level Makefile for tools/java 

SUBDIRS = 

ROOT = ../../..
include $(ROOT)/Makefile.include

libdtnstub: DTNStubImp.c DTNStub.java
	javah -jni net.tinyos.util.DTNStub
	gcc -c -fpic -I dtn/libdtn DTNStubImp.c
	gcc -shared DTNStubImp.o -o libdtnstub.so dtn/libdtn/libdtn.so
