EXES=channelgen

all: $(EXES)

channelgen: channelgen.c
	gcc -Os channelgen.c -o channelgen

install: $(EXES)
	install -d $(prefix)/bin
	install $(EXES) $(prefix)/bin

clean:
	rm -f $(EXES)
