#!/usr/bin/python

import sys
import gtk
import re
import GtkExtra
from random import *
from math import *
from string import *

#############################################################################
# Globals
#############################################################################

BROADCAST = 0xffff
motes = []

#############################################################################
# Base classes
#############################################################################

class counter(gtk.GtkEntry):
  def __init__(self, title, totalctr=None):
    gtk.GtkEntry.__init__(self)
    self.title = title
    self.value = 0
    self.totalctr = totalctr
    self.refresh()
  def tostring(self):
    if (self.totalctr != None):
      if (self.totalctr.value > 0):
        pct = (self.value*1.0 / self.totalctr.value*1.0) * 100.0
      else:
        pct = 0.0
      return self.title+': '+`self.value`+' ('+'%.2f%%)' % pct
    else:
      return self.title+': '+`self.value`
  def refresh(self):
    self.set_text(self.tostring())
  def clear(self):
    self.value = 0
    self.refresh()
  def add(self, addvalue=1):
    self.value = self.value + addvalue
    self.refresh()

totalMsgCounter = counter("Total messages")
broadcastMsgCounter = counter("Broadcast", totalMsgCounter)

class point:
  def __init__(self, x, y):
    self.x = x
    self.y = y
  def dist(self, pt):
    return sqrt(pow(self.x - pt.x, 2) + pow(self.y - pt.y, 2))
  def angle(self, pt):
    xd = abs(pt.x - self.x)
    if (xd == 0): xd = 0.01
    yd = abs(pt.y - self.y)
    an = atan(yd / xd)
    if (pt.x < self.x and pt.y >= self.y): an = pi - an
    if (pt.x < self.x and pt.y < self.y): an = an + pi
    if (pt.x >= self.x and pt.y < self.y): an = (2.0 * pi) - an
    return an

#############################################################################
# Mote class
#############################################################################

class mote:
  def __init__(self, id):
    self.id = id
    self.chosenedges = []
    self.neighbors = []
    self.loc = None

  def setlocation(self, x,y):
    self.loc = point(x,y)

  def getlocation(self):
    return self.loc

  def tostring(self):
    return '['+`self.id`+']'

  def addneighbor(self, nbr):
    self.neighbors.append(nbr)

#############################################################################
# Edge class
#############################################################################

class edge:
  CLOCKWISE = 0
  COUNTER_CLOCKWISE = 1
  LINE = 2

  def __init__(self, node1, node2):
    self.fromnode = getMote(node1)
    self.tonode = getMote(node2)
    if (self.fromnode != None):
      self.fromnode.addneighbor(self)

  def tridir(self, p1, p2, p3):
    test = (((p2.x - p1.x)*(p3.y - p1.y)) - ((p3.x - p1.x)*(p2.y - p1.y)))
    if (test > 0): return COUNTER_CLOCKWISE
    if (test < 0): return CLOCKWISE
    return LINE

  def crosses(self, e):
    if (self.fromnode == None or self.tonode == None 
        or e.fromnode == None or e.tonode == None): return 0
    l1p1 = self.fromnode.loc
    l1p2 = self.tonode.loc
    l2p1 = e.fromnode.loc
    l2p2 = e.tonode.loc

    # Intersecting on the same point != crossing
    if ((l1p1.x == l2p1.x) and (l1p1.y == l2p1.y)): return 0
    if ((l1p2.x == l2p1.x) and (l1p2.y == l2p1.y)): return 0
    if ((l1p1.x == l2p2.x) and (l1p1.y == l2p2.y)): return 0
    if ((l1p2.x == l2p2.x) and (l1p2.y == l2p2.y)): return 0

    test1_a = self.tridir(l1p1, l1p2, l2p1);
    test1_b = self.tridir(l1p1, l1p2, l2p2);
    if (test1_a != test1_b):
      test2_a = self.tridir(l2p1, l2p2, l1p1);
      test2_b = self.tridir(l2p1, l2p2, l1p2);
      if (test2_a != test2_b):
         return 1
    return 0

  def tostring(self):
    return 'edge: '+self.fromnode.tostring()+'->'+self.tonode.tostring()

#############################################################################
# Event classes
#############################################################################

class event:
  def __init__(self, time=None, moteid=None, data=None):
    self.moteid = moteid
    if (moteid != None): 
      self.mote = getMote(moteid)
    self.time = time
    self.data = data

  def match(self, string):
    re_event = re.compile("^(\d+) (\d+) (.*)")
    m = re_event.search(string)
    if (m != None):
      moteid = int(m.group(1))
      time = int(m.group(2))
      data = m.group(3)
      return event(time, moteid, data)

class dbgMsgEvent(event):
  def __init__(self, time=None, moteid=None, msg=None):
    event.__init__(self, time, moteid, msg)

  def match(self, string):
    re_dbg = re.compile("^(\d+) (\d+) DebugMsgEvent (.*)")
    m = re_dbg.search(string)
    if (m != None):
      moteid = int(m.group(1))
      time = int(m.group(2))
      msg = m.group(3)
      return dbgMsgEvent(time, moteid, msg)
    else:
      return None

class radioMsgSentEvent(event):
  def __init__(self, time=None, sender=None, receiver=None, type=None):
    event.__init__(self, time, sender, None)
    self.sender = getMote(sender)
    if (receiver != BROADCAST):
      self.receiver = getMote(receiver)
      self.broadcast = 0
    else:
      self.broadcast = 1
    self.type = type

  def match(self, string):
    re_msg = re.compile("^(\d+) (\d+) RadioMsgSentEvent \[mote \d\] \[Message \S+\s+\[addr=([^\]]+)\]\s+\[type=([^\]]+).*")
    m = re_msg.search(string)
    if (m != None):
      moteid = int(m.group(1))
      time = int(m.group(2))
      recvid = atoi(m.group(3),16)
      type = atoi(m.group(4),16)
      return radioMsgSentEvent(time, moteid, recvid, type)
    else:
      return None

#  re_nb = re.compile("^(\d+) \d+ DebugMsgEvent \[\d+: TestYaoM: neighbors\[\d+\] is (\d+)\]")
#  re_loc = re.compile("^(\d+) \d+ DebugMsgEvent \[\d+: YaoNeighborhoodM: myLocation \(([^,]+),([^\)]+)\)")
#  re_msgs = re.compile("^(\d+) \d+ RadioMsgSentEvent \[mote \d\] \[Message \S+\s+\[addr=([^\]]+)\]\s+\[type=([^\]]+).*");

#############################################################################
# Core functions
#############################################################################

def getMote(id):
  global motes
  for m in motes:
    if (m.id == id): 
      return m
  return None

def addMote(id):
  m = getMote(id)
  if (m == None):
    m = mote(id)
    motes.append(m)
  return m

def processFile(fname):
  f = open(fname, 'r')
  events = []
  for line in f.readlines():
    # Ignore comments
    if (find(line, "#") == 0): continue
    # Debug messages
    ev = dbgMsgEvent().match(line)
    if (ev != None): 
      events.append(ev)
      continue
    # Radio messages
    ev = radioMsgSentEvent().match(line)
    if (ev != None): 
      events.append(ev)
      continue
    # Default to generic event
    ev = event().match(line)
    if (ev != None): events.append(ev)

  return events


def main():
  events = processFile(sys.argv[1])
  for ev in events:
    print "Got event: "+`ev`

if __name__ == '__main__': main()
