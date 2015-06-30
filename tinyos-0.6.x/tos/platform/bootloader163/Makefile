AS     = avr-gcc -x assembler-with-cpp
LD     = avr-ld -mavrmega161
CC     = avr-gcc 
FULLCC = gcc
OBJCOPY= avr-objcopy
CFLAGS = -c -Os -Wall -I/usr/local/avr/include -I. -mmcu=atmega163

#use for base station
#CFLAGS += -DBASE_STATION
#VHDL = wv/motebase.vhd

#use for mobile mote
VHDL = wv/motesch.vhd


SFLAGS = -S -g -Os -I/usr/local/avr/include -I. -mmcu=at90s2343
LIBS   =
PROGRAMER= uisp

all: DOT


%.o : %.c 
	$(CC) $(CFLAGS) -o $@ $<


%.s: %.S
	cpp $< $@ -I/usr/local/atmel/lib/uTools/ava/avr

%.o : %.s
	$(AS) $(CFLAGS) -o $@ $<

%.s : %.c
	$(CC) $(SFLAGS) -o $@ $<

%: %.o
	$(LD) $< -o $@ $(LIBS)

DOT: DOT.o
	$(LD) -o $@ -Ttext 0x3C00 DOT.o

%.install: %.srec
#	sleep 1
#	$(PROGRAMER) -dapa   -dno-poll --erase
	sleep 1
	$(PROGRAMER) -dprog=dapa   --upload if=$<
	sleep 1
	$(PROGRAMER) -dprog=dapa   -dno-poll --verify if=$<

%.srec : %
	$(OBJCOPY) --output-target=srec $< $@

install: DOT.install


clean:
	rm -f *.o DOT DOT.srec Makefile.objs super.h


