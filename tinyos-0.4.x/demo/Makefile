LIBS := -lammote
LIBDIR := -L.

CFLAGS := -Wall -g -D_REENTRANT
INCLUDE := -I.

all: libammote.a forward Demo2.class

forward: forward.c libammote.a
	gcc $(CFLAGS) $(INCLUDE) $(LIBDIR) forward.c -o forward $(LIBS)


Demo2.class: Demo2.java
	javac -classpath .:./GFC Demo2.java

libammote.a: ammote.o
	rm -f libammote.a
	ar -r libammote.a ammote.o

ammote.o: ammote.c ammote.h
	gcc $(CFLAGS) $(INCLUDE) -c ammote.c -o ammote.o

clean:
	rm -f ammote.o libammote.a forward Demo2.class

run:
	./forward &
	java -cp .:./GFC Demo2

