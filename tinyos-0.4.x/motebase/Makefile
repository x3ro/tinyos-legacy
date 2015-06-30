
INCLUDE := -I.

CFLAGS := -Wall -g -D_REENTRANT 

all: libammote.a

libammote.a: ammote.o
	rm -f libammote.a
	ar -r libammote.a ammote.o

ammote.o: ammote.c ammote.h
	gcc $(CFLAGS) $(INCLUDE) -c ammote.c -o ammote.o

clean:
	rm -f ammote.o libammote.a

