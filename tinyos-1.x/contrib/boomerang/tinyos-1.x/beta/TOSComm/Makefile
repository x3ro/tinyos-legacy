#-*-Makefile-*- vim:syntax=make
#$Id: Makefile,v 1.1.1.1 2007/11/05 19:08:59 jpolastre Exp $

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

