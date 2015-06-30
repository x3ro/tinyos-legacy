##
#
##

INCLUDES = -I../bootloader/include -I../bootloader/blinclude
CC = gcc
CFLAGS = -c -g -Wall

BL_SOURCES = GenAttrList.c 

BL_OBJS = $(BL_SOURCES:.c=.o)
EXEC = GenAttr.exe

all: $(BL_SOURCES) $(EXEC)


$(EXEC): $(BL_OBJS)
	$(CC) $(INCLUDES) $(BL_OBJS) $(LIBFLAGS) -o $@
	@echo ""
	@echo "Installation Instruction"
	@echo "  1. Run the $(EXEC) file to create attribute.bin file."
	@echo "  2. Make install"

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

install:
	c:/nordheim/xflash/xflash.exe -p imote2 -fb 0x1E00000 -tt "JTAG CPU" attributes.bin
#	c:/nordheim/xflash/xflash.exe -p imote2 -fb 0x1E00000 -tt "INTEL(R) JTAG CABLE" attributes.bin

clean:
	rm -f $(EXEC)
	rm -f attributes.bin
	rm -f *.o
	rm -f *~
