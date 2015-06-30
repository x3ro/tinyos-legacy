AS     = avr-gcc -x assembler-with-cpp
LD     = avr-gcc -mmcu=at90s2343
CC     = avr-gcc 
FULLCC = gcc
OBJCOPY= avr-objcopy
CFLAGS = -c -Os -Wall -I/usr/local/avr/include -I. -mmcu=at90s2343

#use for base station
#CFLAGS += -DBASE_STATION
#VHDL = wv/motebase.vhd

#use for mobile mote
# added this comment
#VHDL = wv/motesch.vhd


SFLAGS = -S -g -Os -I/usr/local/avr/include -I. -mmcu=at90s2343
LIBS   =
PROGRAMER= uisp

# changed make all
all: Whisker


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

# Changed this to whisker
Whisker: Whisker.o
	$(LD) -o $@ Whisker.o

%.install: %.srec
	sleep 1
	$(PROGRAMER) -dprog=dapa -dlpt=3 -dno-poll --erase
	sleep 1
	$(PROGRAMER) -dprog=dapa -dlpt=3 -dno-poll --upload if=$<
	sleep 1
	$(PROGRAMER) -dprog=dapa -dlpt=3 -dno-poll --verify if=$<

%.srec : %
	$(OBJCOPY) --output-target=srec $< $@

# Changed to whisker
install: Whisker.install

# Changed to whisker
clean:
	rm -f *.o Whisker Whisker.srec Makefile.objs super.h


