# $Id: Makefile,v 1.4 2005/01/19 13:08:12 klueska Exp $
#
# Bootloader for mica2, mica2dot, telos, eyesIFX and eyesNEDAP platforms
# 
# This bootloader is a self-contained executable. Meaning that when
# executed, it will go through the normal init sequence (i.e. set up
# stack, initialize data segment, etc).  Thus, a node can be set to
# always boot into the bootloader first, before invoking the
# application. This allows the user to input a special gesture
# (i.e. reset the node 3 times quickly) to load a golden image stored
# in flash onto the node.
#
# @author Jonathan Hui <jwhui@cs.berkeley.edu>
# @author Jan Hauer (added debug target)
# @since  0.1
#

PRG            = bootloader
OBJ            = bootloader.o
OPTIMIZE       = -Os
IFLAGS         = -Wall,-adhlmsn=$(<:.c=.lst)

ifeq ($(PLATFORMS)_x, _x)
	PLATFORMS = mica2 mica2dot micaz telos eyesIFX eyesNEDAP eyesIFXv2
endif

define USAGE

Usage: 	make <platform>
	make all
	make clean
	make cleanall

	Valid platforms are: $(PLATFORMS)
endef

DEBUG := $(filter debug, $(MAKECMDGOALS))
MAKECMDGOALS := $(filter-out $(DEBUG), $(MAKECMDGOALS))

PLATAUX=$(PLATFORMS) all clean cleanall
PLATFORM := $(filter $(PLATAUX), $(MAKECMDGOALS))

ifeq ($(PLATFORM)_x,_x)
$(error $(PLATAUX) $(MAKECMDGOALS) $(USAGE))
endif

ifeq ($(PLATFORM),mica2)
	INCDIR           = -I./include/avr -I./include/mica2 -I/opt/avr/include
	CC 		 = avr-gcc
	OBJ	        += avr_flash.o
	MCU_TARGET       = atmega128
	BOOTLOADER_START = 0x1f000
	BOOTLOADER_END   = 0x1ffff
	OBJCOPY          = avr-objcopy
	OBJDUMP          = avr-objdump
	DEFS             = -DPLATFORM_MICA2
endif
ifeq ($(PLATFORM),mica2dot)
	INCDIR           = -I./include/avr -I./include/mica2dot -I/opt/avr/include
	CC 		 = avr-gcc
	OBJ	        += avr_flash.o
	MCU_TARGET       = atmega128
	BOOTLOADER_START = 0x1f000
	BOOTLOADER_END   = 0x1ffff
	OBJCOPY          = avr-objcopy
	OBJDUMP          = avr-objdump
	DEFS             = -DPLATFORM_MICA2DOT
endif
ifeq ($(PLATFORM),micaz)
	INCDIR           = -I./include/avr -I./include/micaz -I/opt/avr/include
	CC 		 = avr-gcc
	OBJ	        += avr_flash.o
	MCU_TARGET       = atmega128
	BOOTLOADER_START = 0x1f000
	BOOTLOADER_END   = 0x1ffff
	OBJCOPY          = avr-objcopy
	OBJDUMP          = avr-objdump
	DEFS             = -DPLATFORM_MICAZ
endif
ifeq ($(PLATFORM),telos)
	INCDIR           = -I./include/msp -I./include/telos -I/cygdrive/c/mspgcc/msp430/include
	CC 		 = msp430-gcc
	OBJ	        += msp_flash.o
	MCU_TARGET       = msp430x149
	BOOTLOADER_START = 0x1100
	BOOTLOADER_END   = 0x2fff
	OBJCOPY          = msp430-objcopy
	OBJDUMP          = msp430-objdump
	DEFS             = -DPLATFORM_TELOS
endif
ifeq ($(PLATFORM),eyesIFX)
  ifeq ($(DEBUG), debug)
    OPTIMIZE = -O0 -g
  endif
	INCDIR           = -I./include/msp -I./include/eyesIFX -I$(TOSDIR)/lib/Deluge/TOSBoot/include/msp
	CC 		 = msp430-gcc
	OBJ	        += msp_flash.o
	MCU_TARGET       = msp430x149
	BOOTLOADER_START = 0x1100
	BOOTLOADER_END   = 0x2fff
	OBJCOPY          = msp430-objcopy
	OBJDUMP          = msp430-objdump
	DEFS             = -DPLATFORM_EYESIFX
endif
ifeq ($(PLATFORM),eyesIFXv2)
  ifeq ($(DEBUG), debug)
    OPTIMIZE = -O0 -g
  endif
	INCDIR           = -I./include/msp -I./include/eyesIFXv2 -I$(TOSDIR)/lib/Deluge/TOSBoot/include/msp
	CC 		 = msp430-gcc
	OBJ	        += msp_flash.o
	MCU_TARGET       = msp430x1611
	BOOTLOADER_START = 0x4000
	BOOTLOADER_END   = 0x5fff
	OBJCOPY          = msp430-objcopy
	OBJDUMP          = msp430-objdump
	DEFS             = -DPLATFORM_EYESIFXV2
endif
ifeq ($(PLATFORM),eyesNEDAP)
  ifeq ($(DEBUG), debug)
    OPTIMIZE = -O0 -g
  endif
	INCDIR           = -I./include/msp -I./include/eyesNEDAP -I$(TOSDIR)/lib/Deluge/TOSBoot/include/msp
	CC 		 = msp430-gcc
	OBJ	        += msp_flash.o
	MCU_TARGET       = msp430x149
	BOOTLOADER_START = 0x1100
	BOOTLOADER_END   = 0x2fff
	OBJCOPY          = msp430-objcopy
	OBJDUMP          = msp430-objdump
	DEFS             = -DPLATFORM_EYESNEDAP
endif

DEFS    += -DBOOTLOADER_START=$(BOOTLOADER_START) -DBOOTLOADER_END=$(BOOTLOADER_END)
CFLAGS   = $(OPTIMIZE) $(IFLAGS) -mmcu=$(MCU_TARGET) $(DEFS) $(INCDIR)
LDFLAGS  = -Wl,-Map,$(PRG).map,--section-start=.text=$(BOOTLOADER_START)

mica2: clean $(PRG).elf lst srec
	mv bootloader.srec bl_mica2.srec

mica2dot: clean $(PRG).elf lst srec
	mv bootloader.srec bl_mica2dot.srec

micaz: clean $(PRG).elf lst srec
	mv bootloader.srec bl_micaz.srec

telos: clean $(PRG).elf lst ihex
	mv bootloader.ihex bl_telos.ihex
  
eyesIFX: clean $(PRG).elf lst ihex
	mv bootloader.ihex bl_eyesIFX.ihex
  
eyesIFXv2: clean $(PRG).elf lst ihex
	mv bootloader.ihex bl_eyesIFXv2.ihex  

eyesNEDAP: clean $(PRG).elf lst ihex
	mv bootloader.ihex bl_eyesNEDAP.ihex
        
all:
	for platform in $(PLATFORMS); do \
		$(MAKE) $$platform || exit 1; \
	done

clean:
	rm -rf $(PRG).elf $(PRG).srec $(PRG).ihex *.o *.lst *.map *~

cleanall:
	rm -rf $(PRG).elf *.srec *.ihex *.o *.lst *.map *~

debug:
	@true
  
$(PRG).elf: $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

lst: $(PRG).lst

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

ihex: $(PRG).ihex
srec: $(PRG).srec

%.ihex: %.elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.srec: %.elf
	$(OBJCOPY) -j .text -j .data -O srec $< $@
