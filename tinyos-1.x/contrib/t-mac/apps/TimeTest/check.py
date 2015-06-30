#!/usr/bin/python

import sys,re,serial,time
from types import *

de = file('../../../t-mac/tos/system/TMACEvents.h').readlines()
patt = re.compile("#define[\t ]*([A-Z_0-9]*)[\t ]+((?:0x)?[\dA-F]+)")

defines = {}

for x in de:
	test = patt.search(x)
	if test!=None:
		defines[test.group(1)] = int(test.group(2),0)
		
class PCSerial:
	def __init__(self):
		self.patt = re.compile("0: Uart: ([\dA-Fa-f]+)")
		
	def read(self):
		while True:
			l = sys.stdin.readline()
			m = self.patt.search(l)
			if m!=None:
				#print "uart line",l
				return chr(int(m.group(1),16))

s=None
if len(sys.argv)<2:
	print "need port arg!"
	sys.exit(1)
if len (sys.argv)==3:
	if sys.argv[2] == "pc":
		s = PCSerial()

if s == None:
	try:
		s = serial.Serial(port=sys.argv[1],baudrate=57600,rtscts=0)#,xonoff=1)
	except:
		print "could not open port"
		sys.exit(1)

def bin(inp,minbits=8):
	out = ""
	while inp>0:
		out = str(inp % 2) + out
		inp = int(inp/2)
	if len(out)<minbits:
		out = ((minbits-len(out))*"0")+out
	return out

def clip(num,bits=8):
	if type(num)==ListType:
		s = hex(reduce(lambda x,y:(x<<8L)+y,num))[2:]
	else:
		#str = hex(num)[2:]
		s = str(num)
	if s[-1] == 'L':
		s = s[:-1]
	return s.rjust(bits*2).replace(" ","")

count = 0

init = -1
first = defines.get("TMAC_MIN_EVENT")
while 1:
	x = s.read()
	x = ord(x)-first
	now = time.time()
	print "%.6f" % now,
	print x,x+first
	continue
	
	if init == -1:
		init = now
	else:
		count +=1
		print "avg off of 1s =",abs(1-((now-init)/count)),
		#print "avg meant to be 1s =",(now-init)/count,
	print "" 
