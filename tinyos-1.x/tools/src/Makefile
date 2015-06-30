all: listen
	(cd uisp && ./COMPILE)
	(cd CC1000 && $(MAKE))

install: all
	(cd uisp && $(MAKE) install)
	(cd CC1000 && $(MAKE) install)

clean: 
	(cd uisp && $(MAKE) clean)
	(cd CC1000 && $(MAKE) clean)

listen: raw_listen.c
	gcc raw_listen.c -o listen
