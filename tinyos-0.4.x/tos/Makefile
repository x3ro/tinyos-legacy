AS     = avr-as
LD     = avr-gcc
CC     = avr-gcc 
FULLCC = gcc
OBJCOPY= avr-objcopy
DEFAULT_LOCAL_GROUP = 0x13
MCU=at90s8535
SFLAGS = -S -g -Os -I. -I./system/include -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
CFLAGS = -c -Os -Wall -I. -I./system/include -mmcu=$(MCU) -DDEFAULT_LOCAL_GROUP=$(DEFAULT_LOCAL_GROUP)
TOOLS  = ./tools
ECHO   = echo
#------------------------------------------------------
# Set DESC to point to the structural description
# of the graph of components.  The C files associated
# with those components and the interconnections are generated
# from the .desc description
#--------------------------------------


# Simple blinking LED example
#DESC = apps/blink.desc

#DESC = apps/connect.desc
#DESC = apps/connect_base.desc
#DESC = apps/wave.desc
#DESC = apps/sens_to_leds.desc
#DESC = apps/cnt_to_leds.desc
#DESC = apps/idf_all.desc
#DESC = apps/prog_test.desc
#DESC = apps/cnt_to_rfm.desc
#DESC = apps/basic_db_mote.desc
#DESC = apps/db_base.desc
#DESC = apps/rfm_to_leds.desc
#DESC = apps/cnt_to_leds_and_rfm.desc
#DESC = apps/sens_to_rfm.desc
#DESC = apps/sens_to_leds_and_rfm.desc
#DESC = apps/chirp.desc
#DESC = apps/uart_chirp.desc
#DESC = apps/mags.desc
#DESC = apps/LOGGER_TEST.desc
#DESC = apps/generic_base.desc
#DESC = apps/accel_REC.desc
#DESC = apps/probrouter_light_wakeup_proximity.desc
#DESC = apps/probrouter.desc
#DESC = apps/prog_test.desc
#DESC = apps/generic_base_crc.desc
#DESC = apps/router.desc
#DESC = apps/router_base.desc
#DESC = apps/envmon.desc
#DESC = apps/traffic.desc
#DESC = apps/PROG_TEST.desc
#DESC = apps/analog_to_rfm.desc
#DESC = apps/power_strip.desc
#DESC = apps/bless_test.desc
#DESC = apps/bless_base.desc
#DESC = apps/bless_uart.desc
#DESC = apps/wakeup.desc
#DESC = apps/probrouter_light_wakeup.desc
#DESC = apps/probrouter_light.desc
#DESC = apps/vibes_logger.desc
DESC = apps/transceiver.desc

#CFLAGS += -DBASE_STATION

#--------------------------------------------
# Remainder is common to all mote applications
#-------------------------------------------
SCHEMA = $(subst desc,schema,$(DESC))
ACCESSORS = $(subst desc,c,$(DESC))

LIBS   =
PROGRAMER= uisp 
WIN_PROGRAMER= ./tools/mote_prog.exe
SET_ID=$(TOOLS)/munge_srec
all: moteschema.h Makefile.objs super.h am_dispatch.h main.exe

super.h: $(SCHEMA) moteschema.h $(DESC)
	$(TOOLS)/mksuper_desc $(DESC) > super.h

am_dispatch.h: super.h
	$(TOOLS)/mk_amdisp > am_dispatch.h

system/AMdispatch.c: $(OBJS) system/AM.h system/AMdispatch.template
	(cpp -I. -Isystem/include system/AMdispatch.template | grep -v NULL_FUNC > system/AMdispatch.c)>& /dev/null

Makefile.objs: $(SCHEMA) moteschema.h $(DESC)
	$(TOOLS)/desc2objs system/ $(DESC) > Makefile.objs

All_headers.c: $(HEADER_FILES) Makefile.objs
	$(TOOLS)/desc2hdrs $(HEADER_FILES) > All_headers.c

moteschema.h: $(SCHEMA) $(TOOLS)/parseschema
		if (test -f $(ACCESSORS)) then \
			$(TOOLS)/parseschema $(SCHEMA) moteschema.h $(ACCESSORS) ACCESSORS.c; \
		else \
			touch moteschema.h; \
		fi 

$(TOOLS)/parseschema:
	make -C $(TOOLS)

$(SCHEMA):
	touch $(SCHEMA)


include Makefile.objs

OBJS = system/sched.o $(CUST_OBJS) system/AMdispatch.o
OBJS = system/sched.o $(CUST_OBJS) 


%.s: %.S
	cpp $< $@ 

%.o : %.s
	$(AS) $< -o $@ 

%.s : %.c
	$(CC) $(SFLAGS) -o $@ $<

%.h : %.comp
	$(TOOLS)/mkheader $< > $@

%.o : %.c %.h
	$(CC) $(CFLAGS) -o $@ $<

%: %.o
	$(LD) $< -o $@ $(LIBS)
ifeq ('$(MCU)', 'atmega163')
main.exe: $(OBJS) $(HEADER_FILES) All_headers.o
	$(LD) -Xlinker -M -Xlinker -defsym -Xlinker reprogram=0x3C00  -o $@  -mmcu=$(MCU) $(OBJS) > img.file
	grep _e img.file | grep =\.

else
main.exe: $(OBJS) $(HEADER_FILES) All_headers.o
	$(LD) -Xlinker -M  -o $@  -mmcu=$(MCU) $(OBJS) > img.file
	grep _e img.file | grep =\.
endif




# -dlpt3 required for IBM thinkpad.  Remove on other platforms
install: main.srec
	sleep 1
	$(PROGRAMER) -dapa -dno-poll --erase 
	sleep 1
	$(PROGRAMER) -dapa --upload if=$<
ifeq ('$(MCU)', 'atmega163')
	$(PROGRAMER) -dapa --upload if=dot/DOT.srec
	$(PROGRAMER) -dapa --segment=fuse --upload if=avrfuse.srec
endif
	sleep 1
	$(PROGRAMER) -dapa -dno-poll --verify if=$<

install.%: main.srec
	$(SET_ID) main `echo $@ |sed 's:install.::g'`
	$(PROGRAMER) -dapa -dno-poll --erase 
	sleep 1
	$(PROGRAMER) -dapa --upload if=out.srec
ifeq ('$(MCU)', 'atmega163')
	$(PROGRAMER) -dapa --upload if=dot/DOT.srec
	$(PROGRAMER) -dapa --segment=fuse --upload if=avrfuse.srec
endif
	sleep 1
	$(PROGRAMER) -dapa -dno-poll --verify if=out.srec

install-np.%: main.srec
	$(SET_ID) main `echo $@ |sed 's:install.::g'`
	$(PROGRAMER) -dapa -dno-poll --erase 
	sleep 1
	$(PROGRAMER) -dapa -dno-poll --upload if=out.srec
	sleep 1
	$(PROGRAMER) -dapa -dno-poll --verify if=out.srec

install_windows: main.srec
	$(WIN_PROGRAMER) --erase --speed 124 --upload $<

install_windows.%: main.srec
	$(SET_ID) main `echo $@ |sed 's:install_windows.::g'`
	$(WIN_PROGRAMER) --erase --speed 124 --upload out.srec

%.srec : %.exe
	$(OBJCOPY) --output-target=srec $< $@


clean:
	rm -f *.o system/*.o system/fullpc/dbg.o main.exe main.srec Makefile.objs super.h *.h system/*.h img.file  system/AMdispatch.c All_headers.c ACCESSORS.c ACCESSORS.comp

dist.tgz: main.srec
	$(RM) params.txt dist.tgz 
	date > params.txt
	$(ECHO) "$(CFLAGS)" >>params.txt
	$(CC) --version >> params.txt
	tar -zcvf dist.tgz $(DESC) $(HEADERS) $(CUST_OBJS:.o=.c) params.txt tools super.h Makefile.objs $(CUST_OBJS:.o=.comp) system/sched.c system/include/*.h Makefile MakefilePC system/AMdispatch.template
