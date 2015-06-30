# Makefile for xcommand 
# $Id: Makefile,v 1.2 2004/10/07 23:14:25 mturon Exp $

CC     = gcc
ARMCC  = arm-linux-gcc
#INCDIR = /usr/local/arm/3.3.2/pgsql/include
#LIBDIR = /usr/local/arm/3.3.2/pgsql/lib
#LFLAGS = -lpq -lm
CFLAGS = -O2 -Wall -Wno-format

# Main xcommand sources
SRCS =  xcommand.c xpacket.c xcrc.c
SRCS += xserial.c xsocket.c 

SRCS += apps/cmd_XMesh.c apps/cmd_XSensor.c  
SRCS += apps/cmd_Surge.c apps/cmd_SimpleCmd.c

all: xcmd

xcmd: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LFLAGS)

xcmd-arm: $(SRCS)
	$(ARMCC) -I$(INCDIR) $(CFLAGS) -o $@ $(SRCS) -L$(LIBDIR) $(LFLAGS) 

clean: 
	rm -f *.o boards/*.o xcmd xcmd-arm xcmd.exe
