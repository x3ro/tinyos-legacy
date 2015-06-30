#! /usr/bin/env python
#$Id: testDetectionEvent.py,v 1.9 2005/07/22 20:37:47 phoebusc Exp $

import os, sys, threading
import pytos.util.NescApp as NescApp
import pytos.Comm as Comm

class TestDetection:
  def __init__(self, buildDir='telosb', port='sf@localhost:9001') :
    self.app = NescApp.NescApp(buildDir, port, tosbase=False)
    self.msgQueue = Comm.MessageQueue(10)
    drain = self.app.rpc.receiveComm
    #drain.register( self.app.msgs.DetectionEventMsg, self.msgQueue )
    
    self.msgThread = threading.Thread( target=self.processMessages, args=() )
    self.msgThread.setDaemon(True)
    self.msgThread.start()

  def processMessages( self ) :
    while True :
      (addr,msg) = self.msgQueue.get()
      self.printmsg(msg,True)
      #print msg.event

  def printmsg(self, msg,recurse=False) :
    if type(msg) is list :
      for n in range(len(msg)) :
        print "--- %d ---" % n
        self.printmsg(msg[n],recurse)
    else :
      if recurse and msg.parentMsg is not None :
        self.printmsg(msg.parentMsg,True)
      print msg

  def setFakeLocation(self,  id, x, y ) :
    self.DummyLocationM.setLocation( int(x*256), int(y*256), address=id )

  def setFakeLocations(self,rpc) :
    self.setFakeLocation( 101, 0, 0 )  # 042
    self.setFakeLocation( 107, 1, 0 )  # mxz
    self.setFakeLocation( 108, 2, 0 )  # oya
    self.setFakeLocation( 104, 3, 0 )  # 0g0
    self.setFakeLocation( 103, 4, 1 )  # 0ci
    self.setFakeLocation( 109, 4, 2 )  # q15
    self.setFakeLocation( 102, 4, 3 )  # 053
    self.setFakeLocation( 106, 4, 4 )  # lug
    self.setFakeLocation( 105, 4, 5 )  # ssm


    
if __name__ == "__main__":
    #if the user is running this as a script as opposed to an imported module
    if len(sys.argv) == 3 :
        app = TestDetection(buildDir = sys.argv[1], port = sys.argv[2], )
    elif len(sys.argv) == 2 :
        app = TestDetection(buildDir = sys.argv[1], )
    else:
        app = TestDetection()
