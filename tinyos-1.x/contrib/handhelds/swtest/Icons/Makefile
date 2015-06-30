# A basic makefile for testing the icon functions

MAKEICON=../../tools/scripts/makeicon.py

iconfiles := *.pnm

all: icon_data.h

icon_data.h:  $(iconfiles)
	python $(MAKEICON) $(iconfiles) > $@

clean cleanall:
	-rm icon_data.h
