# Top-level Makefile for tools/java 
TOS = $(shell ncc -print-tosdir)
SUBDIRS = 

ROOT_RMI = ../../../../../..
ROOT = $(TOS)/../tools/java
RemoteTupleSpaceServerSide_Stub.class: RemoteTupleSpaceServerSide.class
	rmic -d $(ROOT_RMI) edu.wustl.mobilab.agilla.rmi.remoteTupleSpace.RemoteTupleSpaceServerSide

include $(ROOT)/Makefile.include

