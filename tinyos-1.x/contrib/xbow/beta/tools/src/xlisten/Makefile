# Makefile for xlisten # $Id: Makefile,v 1.5 2004/09/30 02:53:57 mturon Exp $

CC     = gcc
ARMCC  = arm-linux-gcc
INCDIR = /usr/local/arm/3.3.2/pgsql/include
LIBDIR = /usr/local/arm/3.3.2/pgsql/lib
LFLAGS = -lpq -lm
CFLAGS = -O2 -Wall -Wno-format

# Main xlisten sources
SRCS =  xlisten.c xpacket.c xconvert.c xdb.c
SRCS += xserial.c xsocket.c 

# Add Mote Sensor board support
SRCS += boards/mts300.c boards/mts400.c boards/mts510.c boards/mts101.c
SRCS += boards/mep500.c boards/mep401.c boards/surge.c

# Add Mote Data Aquisition board support
SRCS += boards/mda500.c boards/mda300.c

SRCS += timestamp/timestamp.c

all: xlisten

xlisten: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LFLAGS)

xlisten-arm: $(SRCS)
	$(ARMCC) -I$(INCDIR) $(CFLAGS) -o $@ $(SRCS) -L$(LIBDIR) $(LFLAGS) 

clean: 
	rm -f *.o boards/*.o xlisten xlisten-arm xlisten.exe
