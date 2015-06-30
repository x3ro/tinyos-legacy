#/* $Id: Makefile,v 1.1 2004/04/27 22:29:09 gtolle Exp $ */
#/*////////////////////////////////////////////////////////*/
#/**
# * Author: Terence Tong
# * For Johnathan Hui's Deluge Project
# */
#/*////////////////////////////////////////////////////////*/

HOST = 192.168.1.31
clean:
	rm -f *.o *.srec Makefile.objs super.h *.hex *.cxx *.cof *.sym *.map *.elf 

mica2: 
	cp hardware.h.mica2 hardware.h
	avr-gcc -g -c -Os -Wall -I. -mmcu=atmega128 -o bootloader.o bootloader.c
	avr-ld -T C:\Software\WinAVR\avr\lib\ldscripts\avr5.x -v -mavr5 -Map=bootloader.map -Tdata 0x800100 -o bootloader.elf bootloader.o
	avr-objcopy --output-target=srec bootloader.elf bootloader.srec
	./emptyblank bootloader.srec 
	mv bootloader.srec mica2bl.srec

mica2dot: 
	cp hardware.h.mica2dot hardware.h
	avr-gcc -g -c -Os -Wall -I. -mmcu=atmega128 -o bootloader.o bootloader.c
	avr-ld -T C:\Software\WinAVR\avr\lib\ldscripts\avr5.x -v -mavr5 -Map=bootloader.map -Tdata 0x800100 -o bootloader.elf bootloader.o
	avr-objcopy --output-target=srec bootloader.elf bootloader.srec
	./emptyblank bootloader.srec 
	mv bootloader.srec mica2dotbl.srec

mica2install:
	uisp -dprog=stk500 -dpart=ATmega128 -dhost=$(HOST) --upload if=mica2bl.srec

mica2dotinstall:
	uisp -dprog=stk500 -dpart=ATmega128 -dhost=$(HOST) --upload if=mica2dotbl.srec
