# Top-level Makefile for contrib/ucbRobo/tools/java/net/tinyos/tools

# We do all subdirectories (to allow for optional package installation)
SUBDIRS = $(shell find . -type d -maxdepth 1 | tail +2 | grep -v /CVS)

ROOT := $(shell ncc -print-tosdir)/../tools/java
include $(ROOT)/Makefile.include
