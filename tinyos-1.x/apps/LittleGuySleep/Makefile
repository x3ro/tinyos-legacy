AS     = avr-gcc -x assembler-with-cpp
LD     = avr-gcc -mmcu=at90s2343
CC     = avr-gcc 
FULLCC = gcc
OBJCOPY= avr-objcopy
CFLAGS = -c -O2 -Wall -I/usr/local/avr/include -I. -mmcu=at90s2343

#use for base station
#CFLAGS += -DBASE_STATION
#VHDL = wv/motebase.vhd
PLATFORMS = 

#use for mobile mote
VHDL = wv/motesch.vhd


SFLAGS = -S -g -Os -I/usr/local/avr/include -I. -mmcu=at90s2343
LIBS   =
PROGRAMER= uisp

all: LG_sleep.srec


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

%.exe: %.o
	$(LD) $< -o $@ $(LIBS)

I2CSPI: I2CSPI.o
	$(LD) -o $@ I2CSPI.o

%.install: %.srec
	sleep 1
	$(PROGRAMER) -dprog=dapa_2   -dno-poll --erase
	sleep 1
	$(PROGRAMER) -dprog=dapa_2 -dno-poll   --upload if=$<
#sleep 1
#$(PROGRAMER) -dprog=dapa_2   -dno-poll --verify if=$<

%.srec : %.exe
	$(OBJCOPY) --output-target=srec $< $@

#%.srec : %
#	$(OBJCOPY) --output-target=srec $< $@

install: LG_sleep.install


clean:
	rm -f *.o *.exe *.srec I2CSPI *~ \#*

.DEFAULT:
	


