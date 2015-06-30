# $Id: DelugeDemoGui.py,v 1.4 2005/08/09 00:22:42 jwhui Exp $

#									tab:2
#
#
# "Copyright (c) 2000-2005 The Regents of the University  of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
# CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
#

#
# @author Jonathan Hui <jwhui@cs.berkeley.edu>
#

from copy import deepcopy
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
from pylab import *
from pytos.Comm import Comm, MessageQueue

import sys
import pytos.tools.Drain as Drain
import pytos.util.NescApp as NescApp
import threading
import Tkinter as Tk 

class DelugeNode( object ) :

    def __init__( self, x, y ) :

        self.x = x
        self.y = y
        self.numPgs = 0
        self.numPgsComplete = 0

    def update( self ) :

        text(self.x, self.y+0.2, "%d/%d" % (self.numPgsComplete, self.numPgs));

class DelugeDemoGui( object ) :

    def __init__( self, buildDir="", motecom=None ) :

        self.nodeStats = {}
        self.numPgs = 0

        app = NescApp.NescApp(buildDir, motecom, tosbase=True)

        drain = app.rpc.receiveComm

        self.initializeGui()

        statsMsgQueue = MessageQueue(8)
        drain.register( deepcopy(app.msgs.DelugeStatsMsg) , statsMsgQueue )
        msgThread = threading.Thread(target=self.processMessages,
                                     args=(statsMsgQueue,))
        msgThread.setDaemon(True)
	self.runMsgThread = True
	self.pauseMsgThread = False
        msgThread.start()

        self.tkRoot.mainloop()

    def initializeGui(self) :

        self.tkRoot = Tk.Tk()
        self.frame = Tk.Frame( self.tkRoot )
        self.frame.pack()
        self.fig = figure()
        self.axes = subplot( 111 )
        self.canvas = FigureCanvasTkAgg( self.fig, master = self.tkRoot )  
        self.canvas.show()
        self.canvas.get_tk_widget().pack( side = Tk.TOP, fill = Tk.BOTH, expand = 1 )
        self.toolbar = NavigationToolbar2TkAgg( self.canvas, self.tkRoot )
        self.toolbar.update()
        self.canvas._tkcanvas.pack( side=Tk.TOP, fill=Tk.BOTH, expand=1 )

    def processMessages(self, msgQueue) :

        while True :
            (addr,msg) = msgQueue.get()
            src = msg.getParentMsg("DrainMsg").source
            print "Node %d: Progress : %d of %d" % (src, msg.stats.numPgsComplete, msg.stats.numPgs)

            if src not in self.nodeStats :
		node = DelugeNode( msg.stats.location.x,
				   msg.stats.location.y );
                # node = DelugeNode( (src-1)%3, floor((src-1)/3) )
                self.nodeStats[src] = node

	    self.nodeStats[src].x = msg.stats.location.x;
	    self.nodeStats[src].y = msg.stats.location.y;

            if msg.stats.numPgs == 0 :
                self.numPgs = 1

            if msg.stats.numPgs > self.numPgs :
                self.numPgs = msg.stats.numPgs

            self.nodeStats[src].numPgs = msg.stats.numPgs
            if (msg.stats.numPgsComplete == 0
                or msg.stats.numPgsComplete > self.nodeStats[src].numPgsComplete) :
                self.nodeStats[src].numPgsComplete = msg.stats.numPgsComplete
            self.draw()

    def draw( self ) :
        if len(self.nodeStats) > 0 :
            X = array([n.x for n in self.nodeStats.values()])
            Y = array([n.y for n in self.nodeStats.values()])
            P = array([n.numPgsComplete for n in self.nodeStats.values()])
            clf()
            scatter(X, Y, s=1024, marker='o', c=P, vmin=0, vmax=self.numPgs, faceted=False)
            axis([min(X)-1, max(X)+1, min(Y)-1, max(Y)+1])
            colorbar()
            #self.axes.set_xlim(min(X)-1, max(X)+1)
            #self.axes.set_ylim(min(Y)-1, max(Y)+1)
            #self.xlim = self.axes.get_xlim()
            #self.ylim = self.axes.get_ylim()
            #colorbar()

        for n in self.nodeStats.values() :
            n.update()

        self.canvas.draw()
        

if __name__ == "__main__" :
    
    if len(sys.argv) == 3 :
        app = DelugeDemoGui(buildDir = sys.argv[1], motecom = sys.argv[2], )
    elif len(sys.argv) == 2 :
        app = DelugeDemoGui(buildDir = sys.argv[1], )
    else :
        app = DelugeDemoGui()
