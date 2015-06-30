#-*-Makefile-*-
######################################################################
#
# Main makefile for TOS applications.
#
# Created: 7/20/2001,  Rob von Behren <jrvb@cs.berkeley.edu>
#
#
# To use this, applications need to simply include this file from
# within their own Makefiles.  No other rules should be necessary for
# most applications.
#
# ADDING NEW TARGET PLATFORMS.  This file is organized with the aim to
# make adding new hardware platforms relatively straightforward.
# There are several places below marked with a "HARDWARE PLATFORM"
# comment, describing what needs to be done.
#
######################################################################

# FIXME: determine this automatically
DEFAULT_LOCAL_GROUP = 0x7D



# If you're an IBM Thinkpad, uncomment this line
HOST=THINKPAD


# output directories
# HARDWARE PLATFORM: add new output directories here
RENEBIN     = binrene
DOTBIN     = bindot
MICABIN     = binmica
PCBIN       = binpc
WORKINGDIRS = bin* 

#CFLAGS += -DBASE_STATION
ifeq (,$(BASEDIR)) 
BASEDIR = ../..
endif
TOOLS   = $(BASEDIR)/tools
TOS     = $(BASEDIR)/tos
SYSTEM  = $(TOS)/system
SHARED  = $(TOS)/shared
INCLUDE = -I. -I$(BINDIR) -I$(TOS)/include
AM_DISPATCH_MAP = $(TOS)/include/AM_DISPATCH.mapping


PROGRAMER      = uisp
WIN_PROGRAMER  = $(TOOLS)/mote_prog.exe
SET_ID         = $(TOOLS)/munge_srec


PROGRAMMER_FLAGS=-dprog=dapa -dno-poll 
# -dlpt=3 required for IBM thinkpad.  Remove on other platforms
ifeq ($(HOST),THINKPAD)
	PROGRAMMER_FLAGS += -dlpt=3
endif

######################################################################
# specific defines for different hardware platforms
######################################################################
# HARDWARE PLATFORM: add defs for new platforms below.  Note that the
# name of the binary (main vs main.exe) is used to determine which
# build rule to use.  This should probably be fixed to do something a
# bit nicer in the future.

# the names for the different hardware targets
HARDWARE_TARGETS = mica pc rene

# determine the requested platform from the make command line args.
# Note that only one platform may be built at a time.
ifneq ($(patsubst pc,,$(MAKECMDGOALS)), $(MAKECMDGOALS)) 
    PLATFORM=pc
    PLATFORM_DIR = $(TOS)/platform/$(PLATFORM)
    PLATFORM_DEFAULT_OBJS = $(PLATFORM_DIR)/dbg.o $(PLATFORM_DIR)/events.o \
        $(PLATFORM_DIR)/heap_array.o $(PLATFORM_DIR)/event_queue.o \
        $(PLATFORM_DIR)/rfm_model.o \
        $(PLATFORM_DIR)/rfm_space_model.o $(PLATFORM_DIR)/hardware.o
    PLATFORM_SPECIAL_OBJS = $(BINDIR)/external_comm.o
endif
ifneq ($(patsubst rene,,$(MAKECMDGOALS)), $(MAKECMDGOALS)) 
    PLATFORM=rene
endif
ifneq ($(patsubst dot,,$(MAKECMDGOALS)), $(MAKECMDGOALS)) 
    PLATFORM=dot
endif
ifneq ($(patsubst mica,,$(MAKECMDGOALS)), $(MAKECMDGOALS)) 
    PLATFORM=mica
endif


PLATFORM_DIR = $(TOS)/platform/$(PLATFORM)
INCLUDE = -I. -I$(BINDIR) -I$(TOS)/include -I$(PLATFORM_DIR) -I$(PLATFORM_DIR)/include

# make sure that we have a valid platform name, and define build vars
GOODPLATFORM = no
ifeq ($(PLATFORM),rene)
    MCU=atmega32 -Wl,-m,avrmega161 -Wl,-T,m323.x
    MCU=atmega163
    AS     = avr-as
    LD     = avr-gcc -Xlinker -M -mmcu=atmega161 -Wl,-Map=$(@:.obj=.map),--cref
    LD     = avr-gcc -Xlinker -M -mmcu=atmega163 -Wl,-Map=$(@:.obj=.map),--cref
    CC     = avr-gcc 
    OBJCOPY= avr-objcopy
    CFLAGS = -g -O -c -Wall -Wa,-ahlms=$(@:.o=.lst) $(INCLUDE) -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    BINDIR = $(RENEBIN)
    BINARY = $(BINDIR)/main.obj
    GOODPLATFORM = yes
endif

ifeq ($(PLATFORM),dot)
	MCU=atmega163
    AS     = avr-as
    LD     = avr-gcc -Xlinker -M   -mmcu=$(MCU) 
    CC     = avr-gcc 
    OBJCOPY= avr-objcopy
    CFLAGS = -c -Os -Wall $(INCLUDE) -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    BINDIR = $(DOTBIN)
    BINARY = $(BINDIR)/main.obj
    GOODPLATFORM = yes
endif

ifeq ($(PLATFORM),mica)
	MCU=atmega103
    AS     = avr-as
    LD     = avr-gcc -Xlinker -M   -mmcu=$(MCU) 
    CC     = avr-gcc 
    OBJCOPY= avr-objcopy
    CFLAGS = -c -Os -Wall $(INCLUDE) -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    SFLAGS = -S -Os -Wall $(INCLUDE) -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    LD     = avr-gcc -Xlinker -M -mmcu=$(MCU) -Wl,-Map=$(@:.obj=.map),--cref
    CFLAGS = -g -O -c -Wall -Wa,-ahlms=$(@:.o=.lst) $(INCLUDE) -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    BINDIR = $(MICABIN)
    BINARY = $(BINDIR)/main.obj
    GOODPLATFORM = yes
endif

ifeq ($(PLATFORM),pc)
    AS     = as
    LD     = gcc
    CC     = gcc 
    CFLAGS = -c -O0 -g -Wall $(INCLUDE) -DTOSSIM -DFULLPC -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
    BINDIR = $(PCBIN)
    BINARY = $(BINDIR)/main
    GOODPLATFORM = yes
endif

# no platform needed for make clean
ifeq ($(MAKECMDGOALS),clean)
    GOODPLATFORM = yes
endif 



######################################################################
######################################################################
##                                                                  ##
##                      Begin main rules                            ##
##                                                                  ##
######################################################################
######################################################################


all:
	$(MAKE) mica

ifeq ($(GOODPLATFORM),no)
ifneq (all,$(MAKECMDGOALS))
ifneq (,$(MAKECMDGOALS))
    $(error Unknown platform specified - $(MAKECMDGOALS))
endif
endif
endif


$(HARDWARE_TARGETS): $(BINARY)


# make missing directories
$(BINDIR)/x:
	mkdir $(BINDIR)
	touch $(BINDIR)/x

ifeq (,$(DESC)) 
DESC = $(wildcard *.desc)
ifeq (,$(DESC)) 
$(error No .desc file found!!)
endif
endif

SCHEMA = $(wildcard $(subst desc,schema,$(DESC)))
ifeq (x_$(SCHEMA), x_)
    SCHEMA = $(BINDIR)/$(subst desc,schema,$(DESC))
endif

#accessors are the functions which the schema code uses
#to retrieve sensor values from motes
ACCESSORS = $(subst .desc,_acc.c,$(DESC))

$(BINDIR)/Makefile.objs: $(SCHEMA) $(BINDIR)/moteschema.h $(DESC)
	$(TOOLS)/desc2objs $(DESC) $(SYSTEM) $(PLATFORM_DIR) $(SHARED)  > $@

ifneq ($(GOODPLATFORM),no)
ifneq ($(MAKECMDGOALS),clean)
include $(BINDIR)/Makefile.objs
endif
endif


$(SYSTEM)/AMdispatch.c: $(OBJS) $(SYSTEM)/AM.h $(SYSTEM)/AMdispatch.template
	(cpp -I. -I$(INCLUDE) $(SYSTEM)/AMdispatch.template | grep -v NULL_FUNC > $@) >& /dev/null


COMPS = $(subst .o,.comp,$(PARSED_OBJS))

$(BINDIR)/super.h: $(BINDIR)/x $(SCHEMA) $(BINDIR)/moteschema.h $(DESC) $(COMPS) 
	$(TOOLS)/mksuper_desc $(DESC) $(SYSTEM) $(PLATFORM_DIR) $(SHARED) > $@


$(SCHEMA): $(BINDIR)/x
	touch $(SCHEMA)


$(BINDIR)/am_dispatch.h: $(BINDIR)/x $(BINDIR)/super.h
	$(TOOLS)/mk_amdisp $(AM_DISPATCH_MAP) $(INCLUDE) > $@



$(BINDIR)/moteschema.h: $(BINDIR)/x $(SCHEMA) $(TOOLS)/parseschema
	if (test -f $(ACCESSORS)) then \
		$(TOOLS)/parseschema $(SCHEMA) $@ $(ACCESSORS) ACCESSORS.c; \
		touch $@; \
	else \
		touch $@; \
	fi 


$(TOOLS)/parseschema:
	make -C $(TOOLS) parseschema






SHARED_OBJS = $(addprefix $(BINDIR)/, $(subst $(SHARED)/,,$(filter $(SHARED)/%,$(PARSED_OBJS))))
SYSTEM_OBJS = $(addprefix $(BINDIR)/, $(subst $(SYSTEM)/,,$(filter $(SYSTEM)/%,$(PARSED_OBJS))))
LOCAL_OBJS = $(addprefix $(BINDIR)/, $(subst ./,,$(filter ./%,$(PARSED_OBJS))))
PLATFORM_OBJS = $(addprefix $(BINDIR)/, $(subst $(PLATFORM_DIR)/,,$(filter $(PLATFORM_DIR)/%,$(PARSED_OBJS))))
OBJS = $(SHARED_OBJS) $(SYSTEM_OBJS) $(PLATFORM_OBJS) $(LOCAL_OBJS) $(PLATFORM_DEFAULT_OBJS) $(PLATFORM_SPECIAL_OBJS) $(BINDIR)/sched.o

%.h : %.comp
	$(TOOLS)/mkheader $< > $@

$(SHARED_OBJS) : $(BINDIR)/%.o : $(SHARED)/%.c $(SHARED)/%.h $(BINDIR)/super.h
	$(CC) $(CFLAGS)  -o $@ $<

$(SYSTEM_OBJS) : $(BINDIR)/%.o : $(SYSTEM)/%.c $(SYSTEM)/%.h $(BINDIR)/super.h
	$(CC) $(CFLAGS) -o $@ $<

$(LOCAL_OBJS) : $(BINDIR)/%.o : ./%.c ./%.h $(BINDIR)/super.h
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

$(BINDIR)/external_comm.o :  $(BINDIR)/%.o : $(PLATFORM_DIR)/%.c
	$(CC) $(CFLAGS) -o $@ $<

$(PLATFORM_DEFAULT_OBJS) : $(PLATFORM_DIR)/%.o : $(PLATFORM_DIR)/%.c 
	$(CC) $(CFLAGS) -o $@ $<

$(PLATFORM_OBJS) : $(BINDIR)/%.o : $(PLATFORM_DIR)/%.c $(PLATFORM_DIR)/%.h $(BINDIR)/super.h
	$(CC) $(CFLAGS) -o $@ $<

$(BINDIR)/sched.o : $(BINDIR)/%.o : $(SYSTEM)/%.c
	$(CC) $(CFLAGS) -o $@ $<

$(BINDIR)/dbg.o : $(BINDIR)/%.o : $(SYSTEM)/%.c
	$(CC) $(CFLAGS) -o $@ $<

%.s : %.c
	$(CC) $(SFLAGS) -o $@ $<




# FIXME: generate dependancy files for the .c files
# FIXME: put appropriate dependancies on the Makefile itself 






install: $(BINDIR)/main.srec
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --erase 
	sleep 1
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=$<
	sleep 1
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --verify if=$<

install.%: $(BINDIR)/main.srec
	$(SET_ID) $(BINDIR)/main `echo $@ |sed 's:install.::g'`
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --erase 
	sleep 1	             
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=out.srec
	sleep 1	             
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --verify if=out.srec


install_windows: $(BINDIR)/main.srec
	$(WIN_PROGRAMER) --erase --speed 124 --upload $<

install_windows.%: $(BINDIR)/main.srec
	$(SET_ID) $(BINDIR)/main `echo $@ |sed 's:install_windows.::g'`
	$(WIN_PROGRAMER) --erase --speed 124 --upload out.srec

$(BINDIR)/%.srec : $(BINDIR)/%.elf
	$(OBJCOPY) --output-target=srec $< $@


# HARDWARE PLATFORM: For the time being, these two rules correspond to
# building for the rene and building for the PC.  It may be necessary
# to add specific build rules for different platforms when new ones
# are added.
$(BINDIR)/main.obj: $(BINDIR)/x $(BINDIR)/am_dispatch.h $(OBJS) $(BINDIR)/All_headers.o
	$(LD) -o $(@:.obj=.elf) $(OBJS) 
	elfcoff $(@:.obj=.elf) $(BINDIR) main.obj
#	grep _e $(BINDIR)/img.file | grep =\.


# Ugh. Cruft necessary to compile under cygwin properly
$(BINDIR)/main: $(BINDIR)/x $(BINDIR)/am_dispatch.h $(OBJS) $(BINDIR)/All_headers.o
	@if test $(OSTYPE) = "cygwin"; then \
	echo "$(LD) -o $@ $(OBJS)"; $(LD) -o $@ $(OBJS); \
	else echo "$(LD) -lpthread -lm -o $@ $(OBJS)"; \
	     $(LD) -lpthread -lm -o $@ $(OBJS); \
	fi

clean:
	rm -rf $(WORKINGDIRS) [A-Z]*.h

HEADER_FILES = $(subst .comp,.h,$(COMPS))

$(BINDIR)/All_headers.o: $(COMPS) 
	$(TOOLS)/desc2hdrs $(HEADER_FILES) > $(BINDIR)/All_headers.c
	$(CC) $(CFLAGS) -o $(BINDIR)/All_headers.o $(BINDIR)/All_headers.c
