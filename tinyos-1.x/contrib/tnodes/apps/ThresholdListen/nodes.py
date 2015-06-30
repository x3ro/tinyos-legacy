#!/usr/bin/python

import re,serial,pygame,thread,time,signal,sys,os
from taskthread import *

from parse import Parse
import traceback
import threading

screen_size = (1280.0,950.0)

locations = [
		[1,"One",(67,467),-1],
		[2,"Two",(447,467),-1],
		[3,"Three",(824,467),-1],
		[4,"Four",(1200,467),-1],
	]

class UpdateMap(TaskThread):
	def __init__(self):
		TaskThread.__init__(self)
		self.setInterval(0.5)
		self.g_colour = (0, 255, 0)
		
		self.m_colour = (0, 0, 255)
		pygame.font.init()
		self.font = pygame.font.Font(None,20)
		self.i = 0
		self.min = new_map.get_size()[0]
		self.max = new_map.get_size()[1]

	def task(self):
		pygame.event.pump()

		#if self.test_redraw():
		screen.fill((0,0,0),(0,0,screen_size[0],screen_size[1]))

		screen.blit(new_map,(0,(screen.get_size()[1]-new_map.get_size()[1])/2))
		#screen.blit(new_map,(0,0))
		for point in locations:
			if point[3]!=-1:
				if point[3]<time.time():
					print "Reset "+point[1]
					point[3] = -1
				else:
					#print "Drew "+point[1]
					#print point[3],time.time()
					pygame.draw.circle(screen,self.m_colour,point[2],10)
		#else:
		#	screen.fill((0,0,0),(self.min,0,screen_size[0]-self.min,screen_size[1]))
		pos = self.font.render(str(pygame.mouse.get_pos()),True,pygame.color.Color('red'))
		#print pygame.mouse.get_pos()
		screen.blit(pos, (new_map.get_size()[0]-60, 20))

		screen.lock()

		for i in range(1,len(points)):
			pygame.draw.line(screen,self.g_colour,(self.min+i-1,points[i-1]),(self.min+i,points[i]))
		while len(points)>screen_size[0]-self.min:
			points.pop()
			
		screen.unlock()

		pygame.display.update()
	
	def test_redraw(self):
		global changed
		if changed == True:
			changed = False
			return True
		for point in locations:
			if point[3]!=-1:
				if point[3]<time.time():
					print "Reset "+point[1]
					point[3] = -1
					return True
		return False


class Reader(TaskThread):
	def __init__(self):
		TaskThread.__init__(self)
		self.buf = ""

	def run(self):
		while 1:
			if self._finished.isSet(): return
			c = self.ser.read()
			self.buf += c
			#if len(c)>0:
			#	print "buf \"%s\"\n"%self.buf
			for (pre,r) in self.prog:
				res = pre.search(self.buf)
				if res!=None:
					print "caught!",res.groups(),self.buf[res.start(0):res.end(0)]
					r(res)
					self.buf = self.buf[res.end(0):]

class StringBuffer:
	def __init__(self):
		self.buf = ""
	
	def read(self):
		while len(self.buf)==0:
			pass
		c = self.buf[0]
		self.buf = self.buf[1:]
		return c
	
	def write(self,c):
		self.buf += c

	def getvalue(self):
		return self.buf

class PCSerial(TaskThread):
	def __init__(self):
		TaskThread.__init__(self)
		self.buf = StringBuffer()
		self.p = Parse(self.buf)
		self.p.start()

	def read(self):
		#if len(self.buf.getvalue())>0:
		#	print "value \"%s\"\n"%self.buf.getvalue()
		return self.buf.read()
	
	def shutdown(self):
		self.p.shutdown()
		TaskThread.shutdown(self)

class MapReader(Reader):
	def __init__(self):
		Reader.__init__(self)
		self.prog = [(re.compile("RADIO_TEST_XMIT (\d+)"),self.do)]
		self.ser = PCSerial()

	def do(self,res):
		global changed
		for point in locations:
			if point[0] == int(res.group(1)):
				if point[3]==-1:
					changed = True
				#print "adding to the point..."+str(res.group(1))
				point[3] = time.time()+1
	
	def shutdown(self):
		self.ser.shutdown()
		TaskThread.shutdown(self)
						
points = []
changed = False
drawn_points = []

pygame.init()
#pygame.event.set_grab(True)
pygame.display.set_caption("Tnodes demo")
screen = pygame.display.set_mode(screen_size)#,pygame.HWSURFACE)#|pygame.DOUBLEBUF)
print screen.get_size()
map = pygame.image.load("circles.png").convert()
ratio = min(screen_size[0]/map.get_size()[0],screen_size[1]/map.get_size()[1])
print (map.get_size()[0]*ratio,map.get_size()[1]*ratio)
new_map = pygame.transform.scale(map,(map.get_size()[0]*ratio,map.get_size()[1]*ratio))
screen.blit(new_map,(0,(screen.get_size()[1]-new_map.get_size()[1])/2))
pygame.display.flip()
tasks = [MapReader(),UpdateMap()]

for x in tasks:
	x.start()
clock = pygame.time.Clock()

try:
	while 1:
		pass
except KeyboardInterrupt:
	print "Ctrl-c"
	for x in tasks:
		x.shutdown()
	os._exit(0)

