#-*-makefile-*-
######################################################################
# 
# Makes the XMesh suite of TinyOS applications for all
# sensorboards, platforms, and radio frequencies.
#
#   SUBDIRS = dir1 dir2 ...
#     Specify a list of subdirectories that 'make' should descend into
#
# NOTE: this Makefile requires GNU make, as well as a number of 
#       standard UNIX shell tools.
#
######################################################################
# $Id: Makefile,v 1.5 2005/02/04 01:55:07 mturon Exp $

SUBDIRS = surge  xmts101 xmts310 xmts420 xmda300 xmep401 
DOTDIRS = xmep500 xmts510 xmda500 

all: mica2 micaz mica2dot 

mica2: here
	@for i in $(SUBDIRS); do \
	  if [ -d $$i ]; then \
	    if [ ! -d Suite ]; then \
	  	mkdir Suite Suite/mica2 Suite/mica2dot Suite/micaz; \
	    fi; \
	    if [ -f $$i/Makefile ]; then \
		rm $$i/build/mica2/*.exe; \
		$(MAKE) -C $$i -f ../Makefile.mica mica2; \
		cp $$i/build/mica2/*.exe Suite/mica2; \
	    else \
		echo "***" no Makefile in directory: $(PWD)/$$i; \
	    fi \
	  else \
		echo "***" skipping missing directory: $(PWD)/$$i; \
	  fi; \
	  rm Suite/mica2/main.exe; \
	done

micaz: here
	@for i in $(SUBDIRS); do \
	  if [ -d $$i ]; then \
	    if [ ! -d Suite ]; then \
	  	mkdir Suite Suite/mica2 Suite/mica2dot Suite/micaz; \
	    fi; \
	    if [ -f $$i/Makefile ]; then \
		rm $$i/build/micaz/*.exe; \
		$(MAKE) -C $$i -f ../Makefile.mica micaz; \
		cp $$i/build/micaz/*.exe Suite/micaz; \
	    else \
		echo "***" no Makefile in directory: $(PWD)/$$i; \
	    fi \
	  else \
		echo "***" skipping missing directory: $(PWD)/$$i; \
	  fi; \
	  rm Suite/micaz/main.exe; \
	done

mica2dot: here
	@for i in $(DOTDIRS); do \
	  if [ -d $$i ]; then \
	    if [ ! -d Suite ]; then \
	  	mkdir Suite Suite/mica2 Suite/mica2dot Suite/micaz; \
	    fi; \
	    if [ -f $$i/Makefile ]; then \
		rm $$i/build/mica2dot/*.exe; \
		$(MAKE) -C $$i -f ../Makefile.mica2dot; \
		cp $$i/build/mica2dot/*.exe Suite/mica2dot; \
	    else \
		echo "***" no Makefile in directory: $(PWD)/$$i; \
	    fi \
	  else \
		echo "***" skipping missing directory: $(PWD)/$$i; \
	  fi; \
	  rm Suite/mica2dot/main.exe; \
	done

here: printdir FORCE

printdir:
	@echo "Building... $(PWD)"; 

FORCE:
