all: xee
HDRDIR= ../../../tos/lib/Xee/

# Main xee sources
SRCS =  xee.c xserial.c xpacket.c xcrc.c

xee: $(SRCS) 
	gcc -O1 -o $@ $(SRCS) -I$(HDRDIR)
 
clean: 
	rm xee.exe

