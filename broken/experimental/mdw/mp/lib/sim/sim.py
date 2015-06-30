#!/usr/bin/python

# Simple mote simulation in Python.

import sys
import gtk
#import GtkExtra
from random import *
from math import *

#############################################################################
# Constants
#############################################################################

# Number of motes
NUM_MOTES = 100
# Max distance between radio neighbors
MAX_NEIGHBOR_DISTANCE = 0.25
# Yao graph sector angle
SECTOR_ANGLE = ((2.0 * pi) / 7.0)
# Whether to perform crossing check
INVALIDATE = 1
# Radio probability model
RADIO_PROB_MODEL = 1
RADIO_PROB_SLOPE = 2.0
RADIO_PROB_POWER = 2

# For edge-crossing detection
COUNTER_CLOCKWISE = 0
CLOCKWISE = 1
LINE = 2

# For layout
WINDOW_HEIGHT = 500
WINDOW_WIDTH = 500

LAYOUT_RANDOM = 0
LAYOUT_GRID = 1
LAYOUT_GRID_RANDOM = 2
GRID_RANDOM_DEVIATION = 0.05
MAX_SPACING = 0.1
INIT_RANDOM = 1

DEFAULT_LAYOUT = LAYOUT_GRID_RANDOM

FLAG_RUN = 0
FLAG_REPORT = 0
FLAG_QUIT = 0

#############################################################################
# Globals
#############################################################################

motes = []
neighboredges = []
eventqueue = []
curtime = 0
window = None
pixmap = None
pixmapGC = None
drawingArea = None
whiteColor = None
blackColor = None
redColor = None
greenColor = None
blueColor = None
totalMsgCounter = None
sentMsgCounter = None
dropMsgCounter = None
totalEdgesCounter = None
crossEdgesCounter = None

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

# Events

class event:
  def __init__(self, mote, time):
    self.mote = mote
    self.time = time
  def fire(self):
    print "Cannot fire base event type!"

class initEvent(event):
  def fire(self):
    self.mote.pickEdges()

class msgRecvEvent(event):
  def __init__(self, mote, time, msg):
    event.__init__(self, mote, time)
    self.msg = msg
  def fire(self):
    self.msg.receive(self.mote)

# Queue functions

def timesortcmp(x, y):
  return cmp(x.time, y.time)

def enqueue(ev):
  global eventqueue
  eventqueue.append(ev)
  eventqueue.sort(timesortcmp)

def dequeue():
  global eventqueue, curtime
  if (len(eventqueue) > 0):
    ev = eventqueue.pop(0)
    if (ev.time != curtime):
      curtime = ev.time
    return ev
  else:
    return None

# Messages

class message:
  def __init__(self):
    pass

class pickEdgeMessage(message):
  def __init__(self, edge):
    self.edge = edge
  def receive(self, mote):
    if (INVALIDATE):
      for e in mote.chosenedges:
        if (e.crosses(self.edge)):
          mote.invalidate(self.edge)

#############################################################################
# Mote class
#############################################################################

class mote:
  def __init__(self, id):
    self.id = id
    self.chosenedges = []
    self.neighbors = []
    if (DEFAULT_LAYOUT == LAYOUT_RANDOM): 
      self.loc = point((random() * 0.8) + 0.1, (random() * 0.8) + 0.1)
    if (DEFAULT_LAYOUT == LAYOUT_GRID or DEFAULT_LAYOUT == LAYOUT_GRID_RANDOM):
      side = int(ceil(sqrt(NUM_MOTES)))
      num_rows = side
      num_columns = side
      xspacing = 1.0 / num_columns
      yspacing = 1.0 / num_rows
      if (xspacing > MAX_SPACING): xspacing = MAX_SPACING
      if (yspacing > MAX_SPACING): yspacing = MAX_SPACING
      if (NUM_MOTES > 2):
        xbase = 0.5 - xspacing  * ((side-1) / 2.0)
        ybase = 0.5 - yspacing  * ((side-1) / 2.0)
      else:
        xbase = 0.5 - xspacing  * ((side-1) / 2.0)
        ybase = 0.5
      rownum = id / num_columns
      colnum = id % num_columns
      x = (xspacing * colnum) + xbase
      y = (yspacing * rownum) + ybase
      if (DEFAULT_LAYOUT == LAYOUT_GRID_RANDOM):
        x = x + ((random() * GRID_RANDOM_DEVIATION*2.0) - GRID_RANDOM_DEVIATION)
        y = y + ((random() * GRID_RANDOM_DEVIATION*2.0) - GRID_RANDOM_DEVIATION)
      self.loc = point(x,y)

  def tostring(self):
    return '['+`self.id`+']'

  def addneighbor(self, nbr):
    self.neighbors.append(nbr)

  def draw(self, color):
    global pixmap
    global pixmapGC
    global drawingArea
    x = self.loc.x * WINDOW_WIDTH
    y = self.loc.y * WINDOW_HEIGHT
    pixmapGC.foreground = color
    pixmapGC.line_width = 2
    gtk.draw_rectangle(pixmap, pixmapGC, gtk.FALSE, x-3, y-3, 6, 6)
    pixmapGC.foreground = whiteColor
    gtk.draw_string(pixmap, gtk.load_font("fixed"), pixmapGC, x+3, y-5, str(self.id))
    drawingArea.queue_draw()

  def sendMsg(self, mote, msg):
    global curtime
    global totalMsgCounter
    global sentMsgCounter
    global dropMsgCounter
    totalMsgCounter.add(1)
    if (RADIO_PROB_MODEL):
      prob = max(0.0, 1.0 - pow(mote.loc.dist(self.loc) * RADIO_PROB_SLOPE, RADIO_PROB_POWER))
      if (random() <= prob):
        sentMsgCounter.add(1)
        enqueue(msgRecvEvent(mote, curtime, msg))
      else:  
        dropMsgCounter.add(1)
    else:
      enqueue(msgRecvEvent(mote, curtime, msg))

  def broadcastMsg(self, msg):
    for mote in self.neighbors:
      self.sendMsg(mote, msg)

  def pickEdge(self, chosenmote):
    e = edge(self,chosenmote)
    self.chosenedges.append(edge(self, chosenmote))
    # Tell all neighbors
    self.broadcastMsg(pickEdgeMessage(e))
    # Draw it
    e.draw(whiteColor)

  # Pick all neighbors
  def pickAllNeighbors(self):
    for nr in self.neighbors:
      self.pickEdge(nr)

  # Pick small number of neighbors
  def pickSomeNeighbors(self):
    n = 0
    while (n < 3):
      n = n+1
      chosen = int(random() * len(self.neighbors))
      chosenmote = self.neighbors[chosen]
      self.pickEdge(chosenmote)

  def distsortcmp(self, x, y):
    return cmp(x.loc.dist(self.loc), y.loc.dist(self.loc))

  # Pick closest neighbors
  def pickClosestNeighbors(self):
    nbrs = self.neighbors
    nbrs.sort(self.distsortcmp)
    n = 0
    while (n < 5):
      self.pickEdge(nbrs[n])
      n = n+1

  def anglesortcmp(self, x, y):
    return cmp(x.loc.angle(self.loc), y.loc.angle(self.loc))

  def getsector(self, nbr):
    global SECTOR_ANGLE
    a = nbr.loc.angle(self.loc)
    return (floor(a / SECTOR_ANGLE)) * (SECTOR_ANGLE) * 1.0

  # Pick closest neighbors in each sector
  def pickClosestAngleNeighbors(self):
    nbrs = self.neighbors
    nbrs.sort(self.anglesortcmp)
    cursec = 0.0
    l = []
    for n in nbrs:
      sec = self.getsector(n)
      #print 'neighbor '+`n.id`+' angle '+`n.loc.angle(self.loc)`+ ' dist '+`n.loc.dist(self.loc)`+' sec '+`sec`
      if (sec != cursec):
        if (len(l) > 0):
          l.sort(self.distsortcmp)
	  self.pickEdge(l[0])
        l = []
	cursec = sec
        #print 'NEW LIMIT'
      l.append(n)
    if (len(l) > 0):
      l.sort(self.distsortcmp)
      self.pickEdge(l[0])

  def pickEdges(self):
    self.pickClosestAngleNeighbors()

  def invalidate(self, badedge):
    #print 'INVALIDATING: '+badedge.tostring()
    for e in badedge.fromnode.chosenedges:
      #print e.tostring()
      if ((e.fromnode == badedge.fromnode) and (e.tonode == badedge.tonode)):
        badedge.fromnode.chosenedges.remove(e)
        badedge.draw(redColor)

#############################################################################
# Edge class
#############################################################################

class edge:
  CLOCKWISE = 0
  COUNTER_CLOCKWISE = 1
  LINE = 2

  def __init__(self, node1, node2):
    self.fromnode = node1
    self.tonode = node2

  def draw(self, color, width=0):
    global pixmap
    global pixmapGC
    global drawingArea
    x1 = self.fromnode.loc.x * WINDOW_WIDTH
    y1 = self.fromnode.loc.y * WINDOW_HEIGHT
    x2 = self.tonode.loc.x * WINDOW_WIDTH
    y2 = self.tonode.loc.y * WINDOW_HEIGHT
    pixmapGC.foreground = color
    pixmapGC.line_width = width
    gtk.draw_line(pixmap, pixmapGC, x1, y1, x2, y2)
    drawingArea.queue_draw()

  def tridir(self, p1, p2, p3):
    test = (((p2.x - p1.x)*(p3.y - p1.y)) - ((p3.x - p1.x)*(p2.y - p1.y)))
    if (test > 0): return COUNTER_CLOCKWISE
    if (test < 0): return CLOCKWISE
    return LINE

  def crosses(self, e):
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
# Initialization
#############################################################################

def makeMotes():
  global motes
  for n in range(NUM_MOTES):
    motes.append(mote(n))

# Function to determine whether two motes are neighbors
def isNeighbor(m1, m2):
  if (m1.loc.dist(m2.loc) < MAX_NEIGHBOR_DISTANCE):
    return 1
  else:
    return 0

def makeNeighborEdges():
  global neighboredges
  for i in range(NUM_MOTES):
    for j in range(NUM_MOTES):
      if (isNeighbor(motes[i], motes[j])):
        neighboredges.append(edge(motes[i],motes[j]))
	motes[i].addneighbor(motes[j])
	motes[j].addneighbor(motes[i])

def initMotes():
  if (INIT_RANDOM):
    for m in motes:
      time = int(random() * NUM_MOTES)
      enqueue(initEvent(m, time))
  else:
    for m in motes:
      enqueue(initEvent(m, m.id))


#############################################################################
# Drawing
#############################################################################

def clear():
  pixmapGC.foreground = blackColor
  gtk.draw_rectangle(pixmap, pixmapGC, gtk.TRUE, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
  drawingArea.queue_draw()

def drawMotes():
  global motes
  for m in motes:
    m.draw(blueColor)

def drawNeighborEdges():
  global neighboredges
  for e in neighboredges:
    e.draw(greenColor)

def drawChosenEdges():
  global motes
  for m in motes:
    for e in m.chosenedges:
      e.draw(whiteColor)

def configure_event(widget, event):
  global pixmap
  win = widget.get_window()
  pixmap = gtk.create_pixmap(win, win.width, win.height, -1)
  return gtk.TRUE

def expose_event(widget, event):
  global pixmapGC
  global pixmap
  area = event.area
  #gc = widget.get_style().fg_gc[gtk.STATE_NORMAL]
  widget.draw_pixmap(pixmapGC, pixmap, area[0], area[1], area[0], area[1], area[2], area[3])
  return gtk.FALSE

def doneWithRun():
  global cross_cb
  if (FLAG_REPORT):
    print totalMsgCounter.tostring()
    print sentMsgCounter.tostring()
    print dropMsgCounter.tostring()
    cross_cb(None)
    print totalEdgesCounter.tostring()
    print crossEdgesCounter.tostring()
  if (FLAG_QUIT):
    sys.exit(0)

#############################################################################
# Buttons
#############################################################################

def step_cb(_button):
  global curtime
  ct = curtime
  while (curtime == ct):
    ev = dequeue()
    if (ev != None):
      ev.fire()
    else:
      return

run_idle_cb_tag = None
def run_idle_cb(_ignore):
  global run_idle_cb_tag
  ev = dequeue()
  if (ev != None):
    ev.fire()
    run_idle_cb_tag = gtk.idle_add(run_idle_cb, None)
  else:
    doneWithRun()

def run_cb(_button):
  global run_idle_cb_tag
  run_idle_cb_tag = gtk.idle_add(run_idle_cb, None)

def clear_cb(_button):
  clear()
  drawMotes()
  drawChosenEdges()

def nbrs_cb(_button):
  clear()
  drawMotes()
  drawNeighborEdges()

def cross_cb(_button):
  global motes, totalEdgesCounter, crossEdgesCouner
  for m1 in motes:
    for e1 in m1.chosenedges:
      totalEdgesCounter.add()
      for m2 in motes:
        for e2 in m2.chosenedges:
	  if (e1.crosses(e2)):
	    crossEdgesCounter.add()
	    e1.draw(redColor, 3)
	    e2.draw(redColor, 3)

#############################################################################
# Main
#############################################################################

def main():
  global window
  global pixmap
  global pixmapGC
  global drawingArea
  global whiteColor
  global blackColor
  global redColor
  global greenColor
  global blueColor
  global totalMsgCounter
  global sentMsgCounter
  global dropMsgCounter
  global totalEdgesCounter
  global crossEdgesCounter
  global FLAG_RUN
  global FLAG_REPORT
  global FLAG_QUIT
  global NUM_MOTES

  for arg in sys.argv[1:]:
    if (arg == "-help"):
      print "Usage: sim.py [-run] [-report] [-motes=NUMMOTES]"
      sys.exit(0)
    if (arg == "-run"):
      FLAG_RUN = 1
    if (arg == "-report"):
      FLAG_REPORT = 1
    if (arg[0:7] == "-motes="):
      NUM_MOTES = int(arg[7:])

  makeMotes()
  makeNeighborEdges()
  initMotes()

  window = gtk.GtkWindow() 
  window.set_name("LittleSim")
  window.connect("destroy", gtk.mainquit) 
  window.set_border_width(5)

  vbox = gtk.GtkVBox(spacing=3)
  window.add(vbox)
  vbox.show()

  drawingArea = gtk.GtkDrawingArea()
  drawingArea.size(WINDOW_WIDTH,WINDOW_HEIGHT)
  vbox.pack_start(drawingArea)
  drawingArea.show()

  drawingArea.connect("configure_event", configure_event);
  drawingArea.connect("expose_event", expose_event);
  drawingArea.set_events(gtk.GDK.EXPOSURE_MASK);

  hbox1 = gtk.GtkHBox(spacing=1)
  vbox.pack_start(hbox1)
  hbox1.show()
  hbox2 = gtk.GtkHBox(spacing=1)
  vbox.pack_start(hbox2)
  hbox2.show()
  hbox3 = gtk.GtkHBox(spacing=1)
  vbox.pack_start(hbox3)
  hbox3.show()

  bStep = gtk.GtkButton("Step simulation")
  bStep.connect("clicked", step_cb)
  hbox1.pack_start(bStep)
  bStep.show()

  bRun = gtk.GtkButton("Run simulation")
  bRun.connect("clicked", run_cb)
  hbox1.pack_start(bRun)
  bRun.show()

  bNbrs = gtk.GtkButton("Show neighbors")
  bNbrs.connect("clicked", nbrs_cb)
  hbox1.pack_start(bNbrs)
  bNbrs.show()

  bClear = gtk.GtkButton("Clear invalid edges")
  bClear.connect("clicked", clear_cb)
  hbox1.pack_start(bClear)
  bClear.show()

  bQuit = gtk.GtkButton("Quit");
  bQuit.connect("clicked", window.destroy)
  hbox1.pack_start(bQuit)
  bQuit.show()

  bCross = gtk.GtkButton("Check crossed edges");
  bCross.connect("clicked", cross_cb)
  hbox2.pack_start(bCross)
  bCross.show()

  totalEdgesCounter = counter("Total edges")
  crossEdgesCounter = counter("Crossed edges", totalEdgesCounter)

  totalMsgCounter = counter("Total messages")
  hbox3.pack_start(totalMsgCounter)
  totalMsgCounter.show()

  sentMsgCounter = counter("Sent", totalMsgCounter)
  hbox3.pack_start(sentMsgCounter)
  sentMsgCounter.show()

  dropMsgCounter = counter("Dropped", totalMsgCounter)
  hbox3.pack_start(dropMsgCounter)
  dropMsgCounter.show()

  window.show()
  pixmapGC = window.get_window().new_gc()
  cmap = drawingArea.get_colormap()
  whiteColor = cmap.alloc("white")
  blackColor = cmap.alloc("black")
  redColor = cmap.alloc("red")
  greenColor = cmap.alloc("green")
  blueColor = cmap.alloc("blue")

  clear()
  drawMotes()

  if (FLAG_RUN):
    run_cb(None)

  gtk.mainloop()

if __name__ == '__main__': main()
