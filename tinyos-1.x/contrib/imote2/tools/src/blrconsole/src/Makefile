# 
# Author Junaith Ahemed Shahabdeen
#
#
#

INCLUDES = -I../include 		\
	-I/usr/include/w32api/ddk/ 	\
	-I/usr/include/w32api/ 		\
	-I../include/ddk/ 		\
	-I../../bootloader/include	\
        -I../../bootloader/blinclude

#	-static -nostdlib 

CC = gcc
CFLAGS = -c -g -Wall
LIBFLAGS = -lsetupapi -lhid # -luser32 -lkernel32
BUILD_DIR=build

BL_SOURCES = 			\
	USBComm.c		\
	USBMessageHandler.c	\
	BinImageFile.c		\
	BinImageUpload.c	\
	CommandLine.c           \
	main.c

### 
# External Source that we are using. Usually
# code from the bootloader.
###
BL_SOURCES += ../../bootloader/src/Crc.c

BL_LDFLAGS	= 		\
	-Wl,-Map,pc-app.map

EXEC=$(BUILD_DIR)/USBLoaderHost.exe
DISASSEM=$(BUILD_DIR)/disassemble.S

CLEANFILES = *~ 	\
	*.o 		\
	*.map		\

BL_OBJS = $(BL_SOURCES:.c=.o)

all: $(BUILD_DIR) $(BL_ASM_SRC) $(BL_SOURCES) $(EXEC) $(BIN)

$(BIN): $(EXEC)
	xscale-elf-objdump -S $(EXEC) > $(DISASSEM)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(EXEC): $(BL_OBJS)
	$(CC) $(BL_LDFLAGS) $(INCLUDES) $(BL_OBJS) $(LIBFLAGS) -o $@
	mv -f $(BL_OBJS) *.map $(BUILD_DIR)

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@ 

clean:
	rm -f $(CLEANFILES)
	rm -rf $(BUILD_DIR)
