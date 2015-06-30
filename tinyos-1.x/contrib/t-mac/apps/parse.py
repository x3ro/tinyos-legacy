#!/usr/bin/python

import sys,re,serial,time,os
from types import *
from taskthread import *
import getopt
from datetime import timedelta

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

class Parse(TaskThread):
	def loadpatt(self):
		de = file('../../../t-mac/tos/system/TMACEvents.h').readlines()
		patt = re.compile("#define[\t ]*([A-Z_0-9]*)[\t ]+((?:0x)?[\dA-F]+)")

		self.defines = {}

		for x in de:
			test = patt.search(x)
			if test!=None:
				self.defines[int(test.group(2),0)] = test.group(1)
	
	def __init__(self,outp):
		TaskThread.__init__(self)
		self.o = outp
		self.loadpatt()
		self.s=None
		
		(commands,port) = getopt.getopt(sys.argv[1:],"p",["pc"])
		if len(port)>1:
			print "Only additional option allowed is one port!"
			sys.exit(1)
		if len(port)==0:
			p = os.getenv('MIB510','/dev/tts/0')
			print "Getting port from MIB510 environment var (%s)"%p
		else:
			p = port[0]

		for (option,value) in commands:
			if option in ["p","pc"]:
				self.s == PCSerial()
			else:
				print "Option '%s' is not supported!\n"%option
				sys.exit(1)
		
		if self.s == None:
			try:
				self.s = serial.Serial(port=p,baudrate=57600,rtscts=0,timeout=1)#,xonoff=1)
			except:
				raise Exception, "could not open port %s"%p

	def bin(self,inp,minbits=8):
		out = ""
		while inp>0:
			out = str(inp % 2) + out
			inp = int(inp/2)
		if len(out)<minbits:
			out = ((minbits-len(out))*"0")+out
		return out

	def clip(self,num,bits=8):
		if type(num)==ListType:
			s = hex(reduce(lambda x,y:(x<<8L)+y,num))[2:]
		else:
			#str = hex(num)[2:]
			s = str(num)
		if s[-1] == 'L':
			s = s[:-1]
		return s.rjust(bits*2).replace(" ","")
	
	def run(self):
		outp = self.o
		noret = 0
		multibyte = 0
		needsret = False
		ast = -1
		last_recv = 0
		last_rssi = 0
		last_grab = -1
		todo = ""
		last = 0
		start = time.time()

		leds = {1:"Red",2:"Green",4:"Yellow"}

		count = 0
		bytes = 0
		while 1:
			if self._finished.isSet(): return
			if needsret:
				print >>outp,""
				if todo!="":
					print >>outp,todo
					todo = ""
				needsret = False
			x = self.s.read(1)
			if len(x)==0:
				continue
			count +=1
			#print >>outp,"ord",ord(x),
			#print >>outp,"last",last,"noret",noret,"needsret",needsret
			if noret>0:
				if grab in ["_LED_SET","_LED_UNSET","_LED_TOGGLE"]:
					try:
						print >>outp,leds[ord(x)],
					except:
						print >>outp,self.clip(ord(x),2),
				else:
					multibyte = (multibyte<<8)+ord(x)
				noret -=1
				if noret == 0:
					format = "(0x%%0%dX)"%(bytes*2)
					print >>outp,multibyte,format%multibyte,
					multibyte = bytes = 0
					needsret = True
				last_grab = ""
				continue
			grab = self.defines.get(ord(x),self.clip(ord(x),2))
			#grab = clip(ord(x),2)
			#print "%.6f" % time.time(),grab,ord(x)
			#continue
			for z in range(len(grab)):
				if grab[z] == "_":
					noret +=1
					bytes +=1
				else:
					break
			curr_time = time.time()
			delta_time = timedelta(seconds=curr_time-start)
			print >>outp,"%s%s" % (time.strftime("%H:%M:%S"),str(curr_time-int(curr_time))[1:7]),delta_time,grab,
			if noret==0:
				print >>outp,"" #"noret",noret,
			last = ord(x)
			last_grab = grab

if __name__ == "__main__":
	p = Parse(sys.stdout)
	p.run()
	
