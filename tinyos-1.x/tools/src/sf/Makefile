PROGRAMS=sf sflisten

all: $(PROGRAMS)

sf: sf.c serialsource.c sfsource.c platform.c platform.h serialsource.h sfsource.h
	gcc -O1 -Wall -g -o $@ sf.c serialsource.c sfsource.c platform.c

# For ARM
asf: sf.c serialsource.c sfsource.c platform.c platform.h serialsource.h sfsource.h
	arm-linux-gcc -O1 -Wall -g -o $@ sf.c serialsource.c sfsource.c platform.c

sflisten: sflisten.c sfsource.c platform.c platform.h sfsource.h
	gcc -O1 -Wall -g -o $@ sflisten.c sfsource.c platform.c

clean:
	rm -f $(PROGRAMS) asf

