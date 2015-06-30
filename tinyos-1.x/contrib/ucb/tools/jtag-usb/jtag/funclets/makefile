#makefile for compile/assemble funclets
#
#part of http://mspgcc.sf.net
# chris <cliechti@gmx.net>

#programs. CC is used for all source files incl. .S and .c
#assembler needs the define so that the includes work properly
CC      = msp430-gcc
CPU     = msp430x1121
ASFLAGS = -mmcu=${CPU} -D_GNU_ASSEMBLER_
CFLAGS  = -mmcu=${CPU} -O2 -Wall -g

.PHONY: all clean convert FORCE

#a list of funclets for the default target "all"
all: regtest.a43 blinking.a43 eraseFlash.a43 progFlash.a43 eraseFlash.lst progFlash.lst convert

#pattern rule for funclets
#msp430-ld is used to link and NO libraries are linked!
#a special linker script is used to place the resulting
#programm into the RAM
%.elf: %.o
	msp430-ld -T msp430xRAM.x -o $@ $<

#general rule for an elf->a43 conversion
%.a43: %.elf
	msp430-objcopy -O ihex $< $@

#general rule to make a listing elf->lst
%.lst: %.elf
	msp430-objdump >$@ -DS $<

#convert intel hex/a43 files to includable C files
convert: eraseFlash.a43 progFlash.a43
	python ihex2c.py eraseFlash.a43 eraseFlash
	python ihex2c.py progFlash.a43 progFlash

#clean (some) files generated during compilation
clean:
	rm -f *.o *.elf

