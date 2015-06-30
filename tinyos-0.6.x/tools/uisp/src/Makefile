# Micro In-System Programmer Makefile
# Uros Platise (c) 1999
#
# Check directories and then
#  - to compile type: make
#  - to install type: make install
#  - to run type: uisp
#
# Now tested with g++ 2.95.2, older versions may not work.

# Directory Setup
        UISP_BIN = /usr/local/bin

# The following lines declare compile options.
# Add switch:
#
#   -DNO_DAPA
#
# to remove "Direct AVR Parallel Access" support completely (should not
# be necessary anymore, see the next option).
#
#   -DNO_DIRECT_IO
#
# to remove direct I/O port access for non-PC machines where it doesn't work
# (parallel port support should still work with the Linux ppdev driver).

CXX = g++
CPPFLAGS = -Wall -O3 -g # -DNO_DIRECT_IO # -DNO_DAPA

SRC	= Main.C Terminal.C MotIntl.C Avr.C AvrAtmel.C AvrDummy.C \
	  Serial.C DAPA.C Stk500.C cygwinp.c

OBJ	= Main.o Terminal.o MotIntl.o Avr.o AvrAtmel.o AvrDummy.o \
	  Serial.o DAPA.o Stk500.o cygwinp.o

all:	uisp

uisp:	$(OBJ)
	$(CXX) -o $@ $(OBJ) $(LIBS)

clean:
	rm -f *.o *~
	rm -f uisp

install: uisp
	cp uisp $(UISP_BIN)

