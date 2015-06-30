#!/usr/bin/python

import sys,re,os.path,os
from types import *

sys.path.append(os.path.join(os.getcwd(),".."))
from parse import Parse

class Check(Parse):
	def run(self):
		count = 0

		when = []

		rate = 120.16666666666666666667
		max = 1.0

		while 1:
			x = self.s.read()
			if len(x)==0:
				continue
			grab = self.defines.get(ord(x),clip(ord(x),2))
			now = time.time()
			if grab == "__RADIO_TEST_RECV":
				x = self.s.read()
				x = self.s.read()
				
				when.append(now)
			if grab == "__RADIO_TEST_RECV" or grab == "__RADIO_RSSI":
				print "%.6f" % now,
			else:
				print "grab",grab
			if grab == "__RADIO_TEST_RECV":
			
				init = now-max
				while len(when)>0 and when[0]<=init:
					when = when[1:]
				#print "packets over last 6 seconds = %.2f%%(%d)"%((len(when)/(max*1.0))*100,len(when))
				cap = len(when)/(rate*max/100.0)
				if cap>100.0:
					cap = 100.0
				print "packets over last %.2f seconds = %03.2f%% (%d)"%(max,cap,len(when))
				#print when
			if grab == "__RADIO_RSSI":
				x = self.s.read()
				second = ord(x)
				x = self.s.read()
				rssi = ord(x)
				print "rssi = %d"%((second*256)+rssi)
			
if __name__ == "__main__":
	p = Check(sys.stdout)
	p.run()
			
