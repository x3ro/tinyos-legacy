# Makefile to install tinyos tools

EXES=mote-key toscheck tinyos-serial-configure set-mote-id locate-jre

all: $(EXES)

install: all
	install -d $(prefix)/bin
	install $(EXES) $(prefix)/bin

clean:
