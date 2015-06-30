#
#
#
#
INCLUDES = -I../include -I../blinclude

#	-static -nostdlib 

CC = xscale-elf-gcc
CFLAGS = -c -g -Wall -DMMU_ENABLE
AS = xscale-elf-as -mcpu=iwmmxt -mfpu=softfpa -W -I../include -I../blinclude
BUILD_DIR=build

#	init.c
BL_SOURCES = 			\
	TOSSched.c		\
	main.c			\
	PXA27XHardware.c	\
	HPLInit.c 		\
	Leds.c			\
	PXA27Xdynqueue.c	\
	PXA27XInterrupt.c	\
	PXA27XGPIOInt.c		\
	PXA27XClock.c		\
	USBClient.c		\
	PMIC.c			\
	FlashAccess.c		\
	BinImageHandler.c	\
	BootLoader.c		\
	Crc.c			\
	AttrAccess.c            \
       	
BL_ASM_SRC =		\
	barecrt.s	\
	util.s 		\
	mmu_table.s 	\
	binarymover.s 	\
	flash.s
   	
BL_LDFLAGS	= 			\
	-static -nostartfiles		\
	-Wl,-T,bare.x -Wl,--stats	\
	-Wl,-Map,bl-elf32.map	

EXEC=$(BUILD_DIR)/out.exe
OBIN=$(BUILD_DIR)/out.bin
VECBIN=$(BUILD_DIR)/Vector.bin
TXTBIN=$(BUILD_DIR)/txtdata.bin
DISASSEM=$(BUILD_DIR)/disassemble.S

CLEANFILES = *~ 	\
	*.o 		\
	*.map		\

BL_OBJS = $(BL_SOURCES:.c=.o)
BL_ASM_OBJS = $(BL_ASM_SRC:.s=.o)

all: $(BUILD_DIR) $(BL_ASM_SRC) $(BL_SOURCES) $(EXEC) $(TXTBIN) $(VECBIN)

$(VECBIN): $(EXEC)
	xscale-elf-objcopy --output-target=binary --rename-section .init=.text,alloc,load,readonly,data,content $(EXEC) $(OBIN)
	dd ibs=32 count=1 if=build/out.bin of=build/vector.bin

$(TXTBIN): $(EXEC)
	xscale-elf-objcopy --output-target=binary -j .text -j .data $(EXEC) $(TXTBIN)
	xscale-elf-objdump -D $(EXEC) > $(DISASSEM)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(EXEC): $(BL_ASM_OBJS) $(BL_OBJS)
	$(CC) -v $(BL_LDFLAGS) $(INCLUDES) $(BL_ASM_OBJS) $(BL_OBJS) -o $@
	mv -f *.o *.map $(BUILD_DIR)

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

.S.o:
	$(AS) -o $@ $<

clean:
	rm -f $(CLEANFILES)
	rm -rf $(BUILD_DIR)

#install:
#	c:/nordheim/xflash/xflash.exe -p imote2 -tt "JTAG CPU" $(VECBIN)
#	c:/nordheim/xflash/xflash.exe -p imote2 -tt "JTAG CPU" -fb 0x200000 $(TXTBIN)

install:
	c:/nordheim/xflash/xflash.exe -p imote2 -tt "JTAG CPU" $(VECBIN)
	c:/nordheim/xflash/xflash.exe -p imote2 -tt "JTAG CPU" -fb 0x200000 $(TXTBIN)
#INTEL(R) JTAG CABLE
#	c:/nordheim/xflash/xflash.exe -p imote2 -tt "INTEL(R) JTAG CABLE" $(VECBIN)
#	c:/nordheim/xflash/xflash.exe -p imote2 -tt "INTEL(R) JTAG CABLE" -fb 0x200000 $(TXTBIN)
