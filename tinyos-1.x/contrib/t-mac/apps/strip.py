#!/usr/bin/python

import sys,re

hline = "#line"
number = re.compile('# \d+')

f = open(sys.argv[1])
lines = f.readlines()
f.close()
f = open(sys.argv[1],'w')

for x in lines:
	if x[:len(hline)] != hline and number.match(x)==None:
		print >>f,x,
		#print x,

f.close()
		
