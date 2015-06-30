MCU = -mmcu=at90s2313
CC = avr-gcc
CFLAGS = $(MCU) -Wall -W -Wstrict-prototypes # --save-temps -v
#CFLAGS += -O3
#CFLAGS += -O2
CFLAGS += -Os
CFLAGS += -mtiny-stack -mcall-prologues
#CFLAGS += -mno-tablejump
CFLAGS += -mrtl
CFLAGS += -g
LD = avr-gcc
LDFLAGS = $(MCU) -Wl,-M
PRG = uisp -dprog=stk200 -dlpt=/dev/parport0 -v=3

OBJS = pavr.o

OUT = pavr.elf
SREC = pavr.srec
MAP = pavr.map
LST = pavr.lst

all: $(SREC) $(LST)

$(SREC): $(OUT)
	avr-objcopy --output-target=srec $(OUT) $(SREC)

$(LST): $(OUT)
	avr-objdump -S -h -D $(OUT) > $(LST)

flash-dump:
	$(PRG) --download of=rom.dump

flash-erase:
	$(PRG) --erase

flash-write: $(SREC)
	$(PRG) --upload --verify if=$(SREC)

flash: $(SREC)
	$(PRG) --erase --upload --verify if=$(SREC)

$(OUT): $(OBJS)
	$(LD) $(OBJS) -o $(OUT) $(LDFLAGS) > $(MAP)

clean:
	rm -f $(OBJS) $(OUT) $(SREC) $(MAP) $(LST)

