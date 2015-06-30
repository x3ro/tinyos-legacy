#!/usr/bin/python

# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
# @author Kamin Whitehouse 
#

from Numeric import *
import sys, time, os
import pytos.util.NescApp as NescApp   #the nescTypes stuff
from pylab import *                        #the matplotlib stuff
from matplotlib.numerix import arange, sin, pi, array
from pytos.Comm import Comm         #the python comm stack
from pytos.Comm import MessageQueue        #the message queue
import pytos.tools.Drain as Drain
import Tkinter as Tk                       #the gui stuff
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
import threading
import re

class NodeDetect( object ) :
  
  def __init__( self, strengthRange, ax, pos, decay_time=2 ) :
      
    n = 25
    t = arange(n)*2*pi/n
    self.disc = array([(cos(x),sin(x)) for x in t])
    self.strength = 0
    self.pos = pos
    self.offset = (279, 157)
    self.scale = 1.35
    self.max_size = 5 #0.5
    self.min_size = 0.10 #0.05
    self.size = self.min_size
    self.color = '#ff8000'
    self.decay_time = decay_time
    self.strengthRange = strengthRange
    self.t0 = 0
    v = self.disc * self.size + self.pos
    self.poly = ax.fill( v[:,0], v[:,1], self.color )

  def update( self ) :
    self.poly[0].xy = self.disc * self.size + array(self.pos) * self.scale + self.offset

  def decay_update( self, t1 ) :

    dt = t1 - self.t0
    size = None

    magnitude = (self.strength - self.strengthRange[0])/(self.strengthRange[1]-self.strengthRange[0])
#    magnitude = 1
    
    if dt <= 0 :
      size = self.max_size * magnitude
    elif dt >= self.decay_time :
      size = self.min_size
    else :
      k = cos(pi*dt/self.decay_time)*0.5+0.5
      size = k*self.max_size*magnitude + (1-k)*self.min_size

    self.size = size
    self.update()


class TestDetection( object ) :
    
    def __init__( self , buildDir="", motecom=None, cfgfile="", bgpic="" ) :

        self.nodeDetections = {}

        #import all types, msgs, and enums from the nesc app
        app = NescApp.NescApp(buildDir, motecom, tosbase=True)

        #create a comm stack
        drain = app.rpc.receiveComm
        #self.comm = Comm()
        #self.comm.connect( motecom ) #defaults to MOTECOM env variable if undefined

        self.initializeGui(bgpic)

        #strengthRange is the (min, max) values of detection event strengths
        self.strengthRange=[0,1]

        #if the user passed in a cfgfile, take the locations from there.
        if cfgfile != "" :
          self.cfgfile = True
          locLine = re.compile('^mote\s+(\S+)\s+\S+\s+(\S+)\s+(\S+)')
          self.locations = {}
          infile = open(cfgfile,"r")
          lines = infile.readlines()
          for line in lines :
            match = locLine.match(line)
            if match != None :
              #print "node %s is at x=%s, y=%s\n" % (match.group(1),
              #                                      match.group(2),
              #                                      match.group(3))
              self.locations[int(match.group(1))] = (float(match.group(3)), float(match.group(2)))
              self.nodeDetections[int(match.group(1))] = NodeDetect(
                self.strengthRange,
                self.axes,
                self.locations[int(match.group(1))],
                decay_time=1)
              self.nodeDetections[int(match.group(1))].decay_update(0)
        else :
          self.cfgfile = False
  
        #create a queue for receiving messages and start a thread to process them
        detectionMsgQueue = MessageQueue(1)
        drain.register( app.msgs.DetectionEventMsg , detectionMsgQueue )
        #self.comm.register( app.msgs.DetectionEventMsg , detectionMsgQueue )
        msgThread = threading.Thread(target=self.processMessages,
                                     args=(detectionMsgQueue,))
        msgThread.setDaemon(True)
        self.runMsgThread = True
        self.pauseMsgThread = False
        msgThread.start()

        #create an independent thread to decay the detections over time
        decayThread = threading.Thread(target=self.decayDetections)
        decayThread.setDaemon(True)
        self.runDecayThread = True
        self.pauseDecayThread = False
        decayThread.start()

        # start the GUI thread
        self.tkRoot.mainloop()
        print "testDetection.py exited normally"
            
    def initializeGui(self, bgpic) :

        # create the frame where all the widgets will go
        self.tkRoot = Tk.Tk()
        self.frame = Tk.Frame( self.tkRoot )
        self.frame.pack()
        # create the matplotlib figure for displaying the data

        #plot a picture on there, if provided
        if bgpic != "":
          pic = imread(bgpic)
          xsize,ysize,depth = pic.shape
          self.fig = figure(figsize = (12.7, 8.2))
          self.axes = axes((0,0,1,1))
          self.axes.imshow(pic, aspect='preserve')
          oldA = axis()
          self.newA = [x/4 for x in oldA]
          self.newA[2] = self.newA[2]+170
          self.newA[3] = self.newA[3]+170
          axis(self.newA)
        else:
          self.newA = axis()
          self.fig = figure()
          self.axes = subplot(111)

        #remember the current axis limits
        self.xlim = self.axes.get_xlim()
        self.ylim = self.axes.get_ylim()
        # start/stop button
        self.startButton = Tk.Button( self.frame , text="stop" ,
                                      command = self.toggleStart )
        self.startButton.pack( side = Tk.LEFT )
        # reset button
        self.resetButton = Tk.Button( self.frame , text="reset" ,
                                      command = self.reset )
        self.resetButton.pack( side = Tk.LEFT )
        # quit button
        self.quitButton = Tk.Button( self.frame , text="quit" ,
                                      command = self.quit )
        self.quitButton.pack( side = Tk.LEFT )

        #container object for the figure instance
        self.canvas = FigureCanvasTkAgg( self.fig , master = self.tkRoot )  
        self.canvas.show()
        self.canvas.get_tk_widget().pack( side = Tk.TOP , fill = Tk.BOTH ,
                                          expand = 1 )
        self.toolbar = NavigationToolbar2TkAgg( self.canvas , self.tkRoot )
        self.toolbar.update()
        self.canvas._tkcanvas.pack( side=Tk.TOP , fill=Tk.BOTH , expand=1)

        
    def quit( self ) :
      # Do we need to really stop runMsgThread and runDecayThread?
      self.runMsgThread = False
      self.runDecayThread = False
      self.tkRoot.quit()
      
    def reset( self ) :
##         for i in range(len(self.nodeDetections)):
##             self.nodeDetections[i]=0
        self.draw()
    
    
    def toggleStart( self ) :
        if self.startButton["text"] == "start" :
            self.startButton["text"] = "stop"
            self.pauseMsgThread = False
            self.pauseDecayThread = False
        else :
            self.startButton["text"] = "start"
            self.pauseMsgThread = True
            self.pauseDecayThread = True

    def decayDetections(self) :
        event = threading.Event()
        first = True
        while self.runDecayThread :
          if not(self.pauseDecayThread) :
            t1 = time.time()
            for node in self.nodeDetections.values() :
              node.decay_update( t1 )
            if first :
              event.wait(1)
              first = False
            self.draw()
            event.wait(1.0/200.0)
            
    def processMessages(self, msgQueue) :
        while self.runMsgThread :
          if not(self.pauseMsgThread) :
            (addr,msg) = msgQueue.get()
            src = msg.getParentMsg("DrainMsg").source
            #print "received msg from %d" % src

            if msg.event.strength < self.strengthRange[0]:
              self.strengthRange[0] = msg.event.strength
            if msg.event.strength > self.strengthRange[1]:
              self.strengthRange[1] = msg.event.strength

            if src not in self.nodeDetections:
                node = NodeDetect( self.strengthRange, self.axes, (0,0), decay_time=1)
                self.nodeDetections[src] = node

            self.nodeDetections[src].strength = msg.event.strength
            
            if self.cfgfile == True:
              if src in self.locations.keys() :
                self.nodeDetections[src].pos = self.locations[src]
              else :
                self.nodeDetections[src].pos = (0,0)
            else:
              self.nodeDetections[src].pos = ( msg.event.location.x/256.0, msg.event.location.y/256.0 )
            self.nodeDetections[src].t0 = time.time()

            #self.draw()

    def draw(self):
        #now, if the user isn't zooming or something, update the axis limits
        #if self.xlim == self.axes.get_xlim() and  self.ylim == self.axes.get_ylim() :
# The following lines can be used to auto-scale based one which nodes are available
#         if len(self.nodeDetections) > 0 :
#           pos = array([n.pos for n in self.nodeDetections.values()])
#           xmin = min(pos[:,0]) - 1
#           xmax = max(pos[:,0]) + 1
#           ymin = min(pos[:,1]) - 1
#           ymax = max(pos[:,1]) + 1
#           d = ((xmax - xmin) - (ymax - ymin))/2
#           if d > 0 :
#             ymin -= d
#             ymax += d
#           elif d < 0 :
#             xmin += d
#             xmax -= d
#           self.axes.set_xlim(xmin,xmax)
#           self.axes.set_ylim(ymin,ymax)
          #self.xlim = self.axes.get_xlim()
          #self.ylim = self.axes.get_ylim()
        #self.axes.set_xlim(self.newA[0], self.newA[1])
        #self.axes.set_ylim(self.newA[2], self.newA[3])
        axis(self.newA)
        self.canvas.draw()
        

        
if __name__ == "__main__":
    #if the user is running this as a script as opposed to an imported module
    if len(sys.argv) == 5 :
        app = TestDetection(buildDir = sys.argv[1], motecom = sys.argv[2], cfgfile = sys.argv[3], bgpic = sys.argv[4],)
    elif len(sys.argv) == 4 :
        app = TestDetection(buildDir = sys.argv[1], motecom = sys.argv[2], cfgfile = sys.argv[3],
                            bgpic='small_rfs.png')
    elif len(sys.argv) == 3 :
        app = TestDetection(buildDir = sys.argv[1], motecom = sys.argv[2],
                            cfgfile = '../../../configurations/RfsField.cfg',
                            bgpic='small_rfs.png')
    elif len(sys.argv) == 2 :
        app = TestDetection(buildDir = sys.argv[1], motecom = 'sf@localhost:9001',
                            cfgfile = '../../../configurations/RfsField.cfg',
                            bgpic='small_rfs.png')

    else:
        #app = TestDetection()
        app = TestDetection(buildDir = 'telosb',
                            motecom = 'sf@localhost:9001',
                            cfgfile = '../../../configurations/RfsField.cfg',
                            bgpic='small_rfs.png')

