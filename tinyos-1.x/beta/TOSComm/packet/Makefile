#-*-Makefile-*- vim:syntax=make
#$Id: Makefile,v 1.1 2004/12/22 01:31:48 cssharp Exp $

#@author Cory Sharp <cssharp@eecs.berkeley.edu>


TOSPACKETDIR ?= $(TOSDIR)/../tools/java/net/tinyos/packet

all: FORCE
	javac *.java

install: FORCE
	install *.class $(TOSPACKETDIR)

uninstall: FORCE
	cd $(TOSPACKETDIR)/../packet && rm -f *.class && javac *.java

clean: FORCE
	rm -f *.class


.PHONY: all install uninstall clean FORCE

