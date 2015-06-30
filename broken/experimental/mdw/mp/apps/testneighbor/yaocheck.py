#!/usr/bin/python

import sys
import gtk
import re
import GtkExtra
from random import *
from math import *
import yaograph

# For layout
WINDOW_HEIGHT = 500
WINDOW_WIDTH = 500
SCALING = 100.0

FLAG_RUN = 0
FLAG_REPORT = 0
FLAG_QUIT = 0

#############################################################################
# Globals
#############################################################################

window = None
pixmap = None
pixmapGC = None
drawingArea = None
whiteColor = None
blackColor = None
redColor = None
greenColor = None
blueColor = None

#############################################################################
# Mote class
#############################################################################

class mote(yaograph.mote):
  def __init__(self, id):
    yaograph.mote.__init__(self, id)

  def draw(self, color):
    if (self.loc == None):
      print 'Cannot draw '+self.tostring()
      return
    global pixmap
    global pixmapGC
    global drawingArea
    x = (self.getlocation().x / SCALING) * WINDOW_WIDTH
    y = (self.getlocation().y / SCALING) * WINDOW_HEIGHT
    pixmapGC.foreground = color
    pixmapGC.line_width = 2
    gtk.draw_rectangle(pixmap, pixmapGC, gtk.FALSE, x-3, y-3, 6, 6)
    pixmapGC.foreground = whiteColor
    gtk.draw_string(pixmap, gtk.load_font("fixed"), pixmapGC, x+3, y-5, str(self.id))
    drawingArea.queue_draw()

#############################################################################
# Edge class
#############################################################################

class edge(yaograph.edge):

  def __init__(self, node1, node2):
    yaograph.edge.__init__(self, node1, node1)

  def draw(self, color, width=0):
    if (self.fromnode == None or self.tonode == None): return
    global pixmap
    global pixmapGC
    global drawingArea
    x1 = (self.fromnode.loc.x / SCALING) * WINDOW_WIDTH
    y1 = (self.fromnode.loc.y / SCALING) * WINDOW_HEIGHT
    x2 = (self.tonode.loc.x / SCALING) * WINDOW_WIDTH
    y2 = (self.tonode.loc.y / SCALING) * WINDOW_HEIGHT
    pixmapGC.foreground = color
    pixmapGC.line_width = width
    gtk.draw_line(pixmap, pixmapGC, x1, y1, x2, y2)
    drawingArea.queue_draw()

#############################################################################
# Initialization
#############################################################################

# Function to determine whether two motes are neighbors
def isNeighbor(m1, m2):
  if (m1.loc.dist(m2.loc) < MAX_NEIGHBOR_DISTANCE):
    return 1
  else:
    return 0

def initMotes():
  if (INIT_RANDOM):
    for m in yaograph.motes:
      time = int(random() * NUM_MOTES)
      enqueue(initEvent(m, time))
  else:
    for m in yaograph.motes:
      enqueue(initEvent(m, m.id))

#############################################################################
# Drawing
#############################################################################

def clear():
  pixmapGC.foreground = blackColor
  gtk.draw_rectangle(pixmap, pixmapGC, gtk.TRUE, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
  drawingArea.queue_draw()

def drawMotes():
  for m in yaograph.motes:
    m.draw(blueColor)

def drawNeighborEdges():
  for m in yaograph.motes:
    for e in m.neighbors:
      e.draw(greenColor)

def drawChosenEdges():
  for m in yaograph.motes:
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

def clear_cb(_button):
  clear()
  drawMotes()
  drawNeighborEdges()

def nbrs_cb(_button):
  clear()
  drawMotes()
  drawNeighborEdges()

def cross_cb(_button):
  global totalEdgesCounter, crossEdgesCouner
  for m1 in yaograph.motes:
    for e1 in m1.neighbors:
      totalEdgesCounter.add()
      for m2 in yaograph.motes:
        for e2 in m2.neighbors:
	  if (e1.crosses(e2)):
	    crossEdgesCounter.add()
	    e1.draw(redColor, 3)
	    e2.draw(redColor, 3)

def addMote(id):
  m = yaograph.getMote(id)
  if (m == None):
    m = mote(id)
    yaograph.motes.append(m)
  return m

def readFile(fname):
  re_loc = re.compile("\[\d+: YaoNeighborhoodM: myLocation \(([^,]+),([^\)]+)\)")
  events = yaograph.processFile(fname)
  for ev in events:
    ev.mote = addMote(ev.moteid)
    if (ev.__class__ == yaograph.dbgMsgEvent):
      m = re_loc.search(ev.data)
      if (m != None): 
        x = float(m.group(1))
        y = float(m.group(2))
	print 'SETTING LOC FOR MOTE '+`ev.mote`+' TO '+`x`+','+`y`
        ev.mote.setlocation(x,y)

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
  global broadcastMsgCounter
  global totalEdgesCounter
  global crossEdgesCounter
  global FLAG_RUN
  global FLAG_REPORT
  global FLAG_QUIT
  global NUM_MOTES

  window = gtk.GtkWindow() 
  window.set_name("YaoGraph")
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
  hbox4 = gtk.GtkHBox(spacing=1)
  vbox.pack_start(hbox4)
  hbox4.show()

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

  totalEdgesCounter = yaograph.counter("Total edges")
  hbox3.pack_start(totalEdgesCounter)
  totalEdgesCounter.show()

  crossEdgesCounter = yaograph.counter("Crossed edges", totalEdgesCounter)
  hbox3.pack_start(crossEdgesCounter)
  crossEdgesCounter.show()

  hbox4.pack_start(yaograph.totalMsgCounter)
  yaograph.totalMsgCounter.show()

  hbox4.pack_start(yaograph.broadcastMsgCounter)
  yaograph.broadcastMsgCounter.show()

  window.show()
  pixmapGC = window.get_window().new_gc()
  cmap = drawingArea.get_colormap()
  whiteColor = cmap.alloc("white")
  blackColor = cmap.alloc("black")
  redColor = cmap.alloc("red")
  greenColor = cmap.alloc("green")
  blueColor = cmap.alloc("blue")

  fname = sys.argv[1]
  readFile(fname)

  clear()
  drawMotes()

  if (FLAG_RUN):
    run_cb(None)

  gtk.mainloop()

if __name__ == '__main__': main()
