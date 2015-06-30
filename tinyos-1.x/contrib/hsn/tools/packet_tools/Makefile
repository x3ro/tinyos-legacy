#!/bin/bash

CC=gcc
INCLUDES=-I/usr/include

OSTYPE=$(shell uname -s)
ifneq (,$(findstring CYGWIN,$(OSTYPE)))
#Values for cygwin:
BIN_EXTENSION=.exe
CT=cleartool
else
#Values for non-cygwin:
BIN_EXTENSION=
CT=$(notdir $(wildcard /usr/atria/bin/cleartool))
endif


ifeq ($(DEBUG),1)
OPT = -g 
else
OPT = -O2
endif

CFLAGS += -Wall -g $(OPT)

APPS = uartserver

COMMON_TCL_FILES = uartserver_connector.tcl packet_parser.tcl packet_print_formatter.tcl create_sim_packetdata.tcl uartserver_common.tcl settings_gui_common.tcl stats_gui_common.tcl dialogs.tcl email.tcl automate_experiments_sync.tcl

all: $(APPS)

tclIndex: $(COMMON_TCL_FILES)
	./Create_TclIndex $(COMMON_TCL_FILES)

uartserver: uartserver.c
ifeq ($(CT),)
	VERSION=OSS1
	$(CC)  $(CFLAGS) -DVERSION=\"$$VERSION\" $< -o  $@
else
	(VERSION=`$(CT) ls $< | awk '{print $$1}'`; \
	$(CC)  $(CFLAGS) -DVERSION=\"$$VERSION\" $< -o  $@)
endif

%.o:	%.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $<

clean::
	rm -f *.o
	@for binfile in $(APPS); do \
	    echo "rm -f $$binfile$(BIN_EXTENSION)" ; \
	    rm -f $$binfile$(BIN_EXTENSION) ; \
	done
