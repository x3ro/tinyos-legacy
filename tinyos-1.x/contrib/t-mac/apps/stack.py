#!/usr/bin/python

from popen2 import popen2
import sys,re

sym = popen2('nm -n '+sys.argv[1])
s = sym[0].readlines()
sp = re.compile("([\da-z]{8}) . ([\.A-Za-z0-9_$]*)")
symbols = []
for x in s:
	m = sp.match(x).groups()
	symbols.append((int(m[0],16),m[1]))
#print symbols

addr = re.compile("addr: ([\da-z]{8})")
stack = file(sys.argv[2],'r').readlines()

for x in stack:
	m = addr.search(x)
	if m!=None:
		place = int(m.groups()[0],16)
		for z in range(len(symbols)):
			if symbols[z][0]>place:
				print place,symbols[z-1][1]
				break
