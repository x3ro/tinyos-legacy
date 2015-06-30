CC=gcc

SRCS=gdbcontrol.h gdbcontrol.c
OBJS=gdbcontrol.o main.o
TESTOBJS=gdbcontrol.o test.o
TARGET=controller
TESTTARGET=testcontroller
LDFLAGS=
CFLAGS=-g

all: main test

test: ${TESTOBJS}
	${CC} -o ${TESTTARGET} ${TESTOBJS}	

main: ${OBJS}
	${CC} -o ${TARGET} ${OBJS}

clean: 
	rm -f ${OBJS} ${TARGET} ${TARGET}.exe ${TESTOBJS} ${TESTTARGET} ${TESTTARGET}.exe core.* *.stackdump tags 

gdbcontrol.o: gdbcontrol.h

dist: clean
	cd ..; tar cvfz controller-dist.tar.gz controller
