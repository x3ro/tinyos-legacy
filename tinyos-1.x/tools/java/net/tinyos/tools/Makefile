# $Id: Makefile,v 1.7 2005/07/22 17:52:38 jwhui Exp $
#
# TinyOS Tools Makefile
#
# @author  TinyOS Team
#

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.tools

MIG = mig java
NCG = ncg java

MSGS = SimpleCmdMsg.java LogMsg.java

INITIAL_TARGETS = $(MSGS)

OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

#
# SimpleCmd
#

SIMPLECMD_LIB=$(TOS)/../apps/SimpleCmd

SimpleCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SimpleCmdMsg $(SIMPLECMD_LIB)/SimpleCmdMsg.h SimpleCmdMsg -o $@

LogMsg.java:
	$(MIG) -java-classname=$(PACKAGE).LogMsg $(SIMPLECMD_LIB)/SimpleCmdMsg.h LogMsg -o $@

#
# Clean
#

cleanmig:
	rm -f $(MSGS)
