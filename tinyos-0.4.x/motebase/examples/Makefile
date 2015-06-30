
INCLUDE := -I. -I..
LIBDIR := -L..
LIBS := -lammote

CFLAGS := -Wall -g -D_REENTRANT

all: rtt forward moteproxy

rtt: rtt.c ../libammote.a
	gcc $(CFLAGS) $(INCLUDE) $(LIBDIR) rtt.c -o rtt $(LIBS)

forward: forward.c ../libammote.a
	gcc $(CFLAGS) $(INCLUDE) $(LIBDIR) forward.c -o forward $(LIBS)

moteproxy: moteproxy.c ../libammote.a
	gcc $(CFLAGS) $(INCLUDE) $(LIBDIR) moteproxy.c -o moteproxy $(LIBS)

clean:
	rm -f rtt

