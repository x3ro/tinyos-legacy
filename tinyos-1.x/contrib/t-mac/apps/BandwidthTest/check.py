#!/usr/bin/python

import sys,re,os.path,os,time
from types import *

sys.path.append(os.path.join(os.getcwd(),".."))
from parse import Parse

class Check(Parse):
	def run(self):
		count = 0

		init = -1
		while 1:
			x = self.s.read()
			if len(x)==0:
				continue
			grab = self.defines.get(ord(x),self.clip(ord(x),2))
			if grab == '__RADIO_TEST_RECV':
				x = ord(self.s.read())*256
				x += ord(self.s.read())
				now = time.time()
				print "%.6f: bandwidth = %d" % (now,int(8*(x/1024.0)))

if __name__ == "__main__":
	p = Check(sys.stdout)
	p.run()
	
