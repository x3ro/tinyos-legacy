all: sf

sf: sf.c serialsource.c sfsource.c serialsource.h sfsource.h
	gcc -DDEBUG=1 -lpthread -O1 -Wall -g -o $@ sf.c serialsource.c sfsource.c

# For ARM
asf: sf.c serialsource.c sfsource.c serialsource.h sfsource.h
	arm-linux-gcc -O1 -Wall -g -o $@ sf.c serialsource.c sfsource.c

clean:
	\rm -f *.o sf
