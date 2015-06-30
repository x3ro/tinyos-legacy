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
import pytos.util.ParseArgs as ParseArgs


class NodeDetect( object ) :
  
  def __init__( self, ax, pos, decay_time=2 ) :
      
    n = 25
    t = arange(n)*2*pi/n
    self.disc = array([(cos(x),sin(x)) for x in t])
    self.pos = pos
    self.max_size = 0.5
    self.min_size = 0.05
    self.size = self.min_size
    self.color = '#ff8000'
    self.decay_time = decay_time
    self.t0 = 0
    v = self.disc * self.size + self.pos
    self.poly = ax.fill( v[:,0], v[:,1], self.color )

  def update( self ) :

    self.poly[0].xy = self.disc * self.size + self.pos

  def decay_update( self, t1 ) :

    dt = t1 - self.t0
    size = None

    if dt <= 0 :
      size = self.max_size
    elif dt >= self.decay_time :
      size = self.min_size
    else :
      k = cos(pi*dt/self.decay_time)*0.5+0.5
      size = k*self.max_size + (1-k)*self.min_size

    self.size = size
    self.update()


class TestDetection( object ) :
    
    def __init__( self , buildDir="", motecom=None ) :

        self.nodeDetections = {}

        #import all types, msgs, and enums from the nesc app
        app = NescApp.NescApp(buildDir, motecom, tosbase=True)

        #create a comm stack
        drain = app.rpc.receiveComm
        #self.comm = Comm()
        #self.comm.connect( motecom ) #defaults to MOTECOM env variable if undefined

        self.initializeGui()

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
            
    def initializeGui(self) :

        # create the frame where all the widgets will go
        self.tkRoot = Tk.Tk()
        self.frame = Tk.Frame( self.tkRoot )
        self.frame.pack()
        # create the matplotlib figure for displaying the data
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
            event.wait(1.0/20.0)
            
    def processMessages(self, msgQueue) :
        while self.runMsgThread :
          if not(self.pauseMsgThread) :
            (addr,msg) = msgQueue.get()
            src = msg.getParentMsg("DrainMsg").source
            print "received msg from %d" % src

            if src not in self.nodeDetections:
                node = NodeDetect( self.axes, (0,0), decay_time=1 )
                self.nodeDetections[src] = node

            self.nodeDetections[src].pos = ( msg.event.location.x/256.0, msg.event.location.y/256.0 )
            self.nodeDetections[src].t0 = time.time()

            #self.draw()

    def draw(self):
        #now, if the user isn't zooming or something, update the axis limits
        #if self.xlim == self.axes.get_xlim() and  self.ylim == self.axes.get_ylim() :
        if len(self.nodeDetections) > 0 :
          pos = array([n.pos for n in self.nodeDetections.values()])
          xmin = min(pos[:,0]) - 1
          xmax = max(pos[:,0]) + 1
          ymin = min(pos[:,1]) - 1
          ymax = max(pos[:,1]) + 1
          d = ((xmax - xmin) - (ymax - ymin))/2
          if d > 0 :
            ymin -= d
            ymax += d
          elif d < 0 :
            xmin += d
            xmax -= d
          self.axes.set_xlim(xmin,xmax)
          self.axes.set_ylim(ymin,ymax)
          #self.xlim = self.axes.get_xlim()
          #self.ylim = self.axes.get_ylim()
        #self.axes.set_xlim(-1, 11)
        #self.axes.set_ylim(-1, 11)
        self.canvas.draw()

        
if __name__ == "__main__":
    #if the user is running this as a script as opposed to an imported module
    args = ParseArgs.ParseArgs(sys.argv)
    app = TestDetection(args.buildDir, args.motecom)


