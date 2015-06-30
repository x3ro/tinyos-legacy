# Top-level Makefile for tools/java 
TOS = $(shell ncc -print-tosdir)
SUBDIRS = 

ROOT_RMI = ../../../../../..
ROOT = $(TOS)/../tools/java
AgentInjectorServerSide_Stub.class: AgentInjectorServerSide.class
	rmic -d $(ROOT_RMI)  edu.wustl.mobilab.agilla.rmi.agentInjector.AgentInjectorServerSide
include $(ROOT)/Makefile.include



