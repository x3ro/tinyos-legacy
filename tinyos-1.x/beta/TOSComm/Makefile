#-*-Makefile-*- vim:syntax=make
#$Id: Makefile,v 1.3 2005/09/22 03:53:12 kaminw Exp $

#@author Cory Sharp <cssharp@eecs.berkeley.edu>


all: FORCE
	cd comm && make && make install 
	cd packet && make && make install

reinstall: FORCE
	cd comm && make install
	cd packet && make install

uninstall: FORCE
	cd comm && make uninstall
	cd packet && make uninstall

clean: FORCE
	cd comm && make clean
	cd packet && make clean

.PHONY: FORCE

