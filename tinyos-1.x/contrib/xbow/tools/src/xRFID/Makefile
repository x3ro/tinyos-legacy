# Makefile for xRFID # $Id: Makefile,v 1.1 2005/03/31 07:51:06 husq Exp $

CC     = gcc
ARMCC  = arm-linux-gcc
INCDIR = /usr/local/arm/pgsql/include
LIBDIR = /usr/local/arm/pgsql/lib
LFLAGS = -lm -lpq
CFLAGS = -O2 -Wall -Wno-format


# Main xRFID sources
SRCS =  xRFID.c xpacket.c
SRCS += xserial.c xsocket.c xdb.c
SRCS += SkyeReadMini/MiniResponse.c
SRCS += SkyeReadMini/MiniCommand.c
INCDIR += timestamp SkyeReadMini 

all: xRFID

xRFID: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LFLAGS)

xRFID-arm: $(SRCS)
	$(ARMCC) -I$(INCDIR) $(CFLAGS) -o $@ $(SRCS) -L$(LIBDIR) $(LFLAGS) 

clean: 
	rm -f *.o boards/*.o xRFID xRFID-arm xRFID.exe
