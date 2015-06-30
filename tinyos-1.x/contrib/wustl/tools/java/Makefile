# Top-level Makefile for tools/java 

# We do all subdirectories (to allow for optional package installation)
SUBDIRS = $(shell find . -maxdepth 1 -type d  | tail +2 | grep -v /CVS)
TOS = $(shell ncc -print-tosdir)
#ROOT = ../..
ROOT = $(TOS)/../tools/java
include $(ROOT)/Makefile.include
