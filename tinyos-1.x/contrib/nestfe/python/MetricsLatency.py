# Latency Probing tools for interacting with MetricsMote and
# TestDetectionEvent with the KrakenMetrics module
#
# USAGE:
# 1) setup your PYTHONPATH to include the directory containing
#    this file
# -- Option I --
# 2a) Start PyTOS using PytosShell.py in the TestDetectionEvent or
#     MetricsMote directory
# 2b) assign appType appropriately at the console
#       Valid options are: "TestDetectionEvent", "MetricsMote"
#       (see bottom of file for details)
# 2c) at the PyTOS command prompt type
#       from MetricsLatency import *
# -- Option II --
# 2) Start up PyTOS using MetricsShell.py
# 3) Interact with Program via keypresses
#
# See nestfe/nesc/apps/MetricsTools for more details
# See also nestfe/scripts/metrics/sh for startup examples
#
# KNOWN LIMITATIONS :
# * Since Timestamping is done entirely on the mote, it is difficult
#   to get timestamps using different motes.
# * To not step on the ping sequence numbers used by MetricsTools, the
#   sequence numbers used by the latency thread are hardcoded to be
#   limited to the range 0-10000, and wrap around as necessary.
#
# IMPLEMENTATION:
# For MetricsLatency, the general message handling flow is:
# 1) messages arrive and are processed by the message handling thread
#    running processMessages().  Messages are distributed to the
#    latency thread through pingQ.
# 2) the latency thread processes the messages and outputs to the
#    screen.  The user can supress/configure the output by typing at
#    the console.
# 
# Timestamping is done entirely on the mote.  2^(32-15)/60*60 = 36 hours
# before the counter on the mote wraps around (32 bit counter, 1/2^15
# seconds per counter increment)


import os, sys
import threading
from Queue import Queue
from time import sleep, time

#Jpype stuff for threads.  Necessary to send messages
from jpype import attachThreadToJVM, isThreadAttachedToJVM

#Pytos stuff
from __main__ import app
from __main__ import appType
import pytos.Comm as Comm
from pytos.Comm import MessageQueue
import pytos.util.KeyPress as KeyPress

##### See bottom of file for executed code when module is imported #####


#################### External Functions ####################
# helper function for map
# returns nth elements in a list of pairs
# used by processLatency()
def get1(x): return x[0]
def get2(x): return x[1]

class MetricsLatency( object ):

   def __init__(self,sendComm,recvComm,appType="MetricsMote"):
      """
      Creation of MetricsLatency object to allow background thread processing.
        appType - Flag to determine how to parse messages
                  (MetricsMote, TestDetectionEvent)
        recvComm - Comm object for receiving messages
        sendComm - Comm object for sending messages
      """

      self.appType = appType # for debugging
      self.running = True

      ## Display Configurations
      print "\nType \"h\" for help\n"
      self.keyPress = KeyPress.KeyPress()
      self.verbosity = '4'
      self.numLostUpdates = 0
      self.outputFlag = True

      ## Latency Thread
      self.runLatThread = False
      self.latMsg = app.msgs.MetricsCmdMsg
      self.pingQ = Queue(2) #should only need 1
      self.latOneThreadSphore = threading.Semaphore() # ensures one
                                                  #thread running at a time
      self.latSemaphore = threading.Semaphore()
      self.latMote = -1 # should not match any real packets
      self.latSeq = -1
      self.minTimeout = 0
      self.maxTimeout = 10
      self.minDelay1 = 0
      self.maxDelay1 = 1
      self.minDelay2 = 0.1
      self.maxDelay2 = 100
      # Default settings
      self.nodeIDs = [0]
      self.numPing = 5
      self.timeout = 2
      self.delay1 = 0.1
      self.delay2 = 0.5

      ## Message Handling
      self.sendComm = sendComm
      self.recvComm = recvComm
      msgQ = MessageQueue(10);

      if (appType == "TestDetectionEvent"):
         # recvComm is a drain connection (shouldn't matter)
         self.msgList = [app.msgs.MetricsReplyMsg,
                         app.msgs.DetectionEventMsg]
         self.AM_METRICSREPLYMSG = app.enums.MetricsTypes.AM_METRICSREPLYMSG
         self.AM_DETECTIONEVENTMSG = app.enums.AM_DETECTIONEVENTMSG
      else: # assume appType == MetricsMote
         self.msgList = [app.msgs.MetricsReplyMsg]
         self.AM_METRICSREPLYMSG = app.enums.MetricsTypes.AM_METRICSREPLYMSG
         self.AM_DETECTIONEVENTMSG = None
         
      for msgName in self.msgList:
         recvComm.register(msgName, msgQ)
 
      msgThread = threading.Thread(target=self.processMessages,
                                   args=(msgQ,))
      msgThread.setDaemon(True)
      msgThread.start()

      
   ##### External Commands #####
   def latencyTest(self,nodeIDs,numPings,timeout,delay1,delay2):
      """
      Starts a thread to ping a node several times and display the
      latency statistics.  Does one round of pings through all the
      nodes at a time, for numPings rounds.
        nodeIDs - a list (or singleton) of noteIDs of nodes being pinged
        numPings - the number of ping requests over which to measure
                   the latency
        timeout - time in seconds before giving up processing for a
                  ping request
        delay1 - delay between pinging different nodes
        delay2 - below between rounds of pinging

      METHOD: maintains internal state on the last used sequence number
              for the pings, so we can call latencyTest again later with
              no difficulty interpreting the output
      OUTPUT: When the thread is finished, it will print a 'finished'
              message to the console
      """
      if isinstance(nodeIDs,int): # must be a singleton
         nodeIDs = [nodeIDs] # make into a list for later
      latThread = threading.Thread(target=self.processLatency,
                                   args=(nodeIDs,numPings,timeout,delay1,delay2))
      latThread.setDaemon(True)
      latThread.start()
      

   ##### Internal Code #####
   def processMessages(self,msgQ):
      """
      Thread message handling code.  Messages handling includes printing
      notifications to the screen, distributing messages to the
      latency queue.

      THREAD SYNCHRONIZATION DETAILS:
      Synchronization with Latency Thread because user may want to run
      his/her own ping queries while the Latency Thread is running in
      the background.  Semaphore used to ensure comparisons done with
      consistent state.
      """
      while self.running :
         (addr,msg) = msgQ.get()
         if ((msg.amType == self.AM_METRICSREPLYMSG) and 
             (msg.msgType == app.enums.MetricsTypes.PING_REPLY)):
            # synchronize with latency ping thread
            self.latSemaphore.acquire()
            if (msg.nodeID == self.latMote) and (msg.data == self.latSeq):
               self.pingQ.put(msg)
            self.latSemaphore.release()
                     
   def calcLat(self,numSent):
      """
      Helper function for processLatency.
      """
      for nodeID in sorted(self.latTable.keys()):
         latList = self.latTable[nodeID]
         numReply = len(latList)
         if (numReply == 0):
            avgLat = 0
         else:
            avgLat = sum(map(get2,latList))/numReply
         succRate = numReply/numSent
         self.latStats[nodeID].append([avgLat,numReply,numSent,succRate])

   def processLatency(self,nodeIDs,numPings,timeout,delay1,delay2):
      """
      Latency Thread code.  Pings nodes periodically to get latency
      statistics.  One ping, one response before proceeding to the next
      ping.  Proceeds through nodes in batches.

      Sequence numbers are limited to the range 0-10000
      INTERNAL VARIABLES
      self.latTable dict key:nodeID value:list of (seqNo,timeDelta)
      self.latStats dict key:nodeID value:(avg_latency,trans_rate)
      """
      self.latOneThreadSphore.acquire()
      if (self.running == False): return #quit all threads that haven't really started
      self.runLatThread = True
      attachThreadToJVM() # will crash if this is not included
      seqNo = 1;
      self.latTable = dict([(x,[]) for x in nodeIDs])
      self.latStats = dict([(x,[]) for x in nodeIDs])
      while self.runLatThread and ((seqNo <= numPings) or numPings < 0):
         if (seqNo != 0): sleep(delay2) # wait to space out pings
         for addr in nodeIDs:
            self.latSemaphore.acquire()
            self.latMote = addr
            self.latSeq = seqNo % 10000
            self.latSemaphore.release()
              # empty the ping queue if message arrives after timeout
              # to keep ping and response synchronized
            for i in range(1,self.pingQ.qsize()):
               msg = self.pingQ.get_nowait()
               self.dispLateReply(msg)
            # Send message
            self.latMsg.cmd = app.enums.MetricsTypes.PING
            self.latMsg.data = self.latSeq
            self.sendComm.send(addr,self.latMsg)
            # Wait for response and process
            try :
               msg = self.pingQ.get(True,timeout)
                 # convert from 2^-15 seconds (32kHz) to milliseconds, modulus
                 # wrap around for counter
               tDelta = float(((msg.tsReply - msg.tsSend) % 0xffffffff) >> 5)
                 # msg.data is sequence number of reply
               self.latTable[msg.nodeID].append([msg.data,tDelta])
               self.dispReply(msg.nodeID,msg.data,tDelta,msg)
            except :
               self.dispTimeout(addr,self.latSeq)
            sleep(delay1) # wait between nodes to clear network traffic
         seqNo+= 1 #inside while-loop
      # Process and print a summary
      self.calcLat(seqNo-1) #argument is number of packets sent
      self.dispLat()
      self.runLatThread = False # synchronize with ping() command
      print "Latency Test Done!"
      self.latOneThreadSphore.release()

   ##### Display Functions #####
   def dispLateReply(self,msg):
      """
      Display when a ping's reply has been too late
      """
      if (int(self.verbosity) > 7):
         tDelta = float(((msg.tsReply - msg.tsSend) % 0xffffffff) >> 5)
         dispStr = ("Node: %d, Ping SeqNo: %d   responded with latency %.2f ms"
                    %(msg.nodeID,msg.data,tDelta))
      # Display Output
      if (self.outputFlag == True):
         print dispStr
      else :
         self.numLostUpdates += 1

   def dispReply(self,nodeID,seqNo,tDelta,msg):
      """
      Display when a ping has replied.
      """
      if (int(self.verbosity) > 3):
         dispStr = ("Node: %d, Ping SeqNo: %d   responded with latency %.2f ms"
                    %(nodeID,seqNo,tDelta))
      ## freezes display... fix later
      #if (int(self.verbosity) == 9):
      #   dispStr = dispStr + msg.__str__()
      # Display Output
      if (self.outputFlag == True):
         print dispStr
         if (int(self.verbosity) == 9):
            print msg
      else :
         self.numLostUpdates += 1

   def dispTimeout(self,addr,seqNo):
      """
      Display when a ping has timed out based on verbosity levels.
      """
      if (int(self.verbosity) > 3):
         dispStr = ("Node: %d, Ping SeqNo: %d  Ping Timeout."
                    %(addr,seqNo))
      # Display Output
      if (self.outputFlag == True):
         print dispStr
      else :
         self.numLostUpdates += 1


   def dispLat(self):
      """
      Displays latency output, based on verbosity levels.
      """
      if (int(self.verbosity) >= 0): #All verbosity levels for now
         for nodeID in sorted(self.latStats.keys()):
            last = len(self.latStats[nodeID])-1
            [avgLat,numReply,numSent,succRate] = (self.latStats[nodeID])[last]
            dispStr = ("Node: %d  average latency %.2f ms, success rate %d/%d (%d %%)"
                       %(nodeID,avgLat,numReply,numSent,succRate*100))
      else:
         dispStr = ""
      # Display Output
      if (self.outputFlag == True):
         print dispStr
      else :
         self.numLostUpdates += 1

   def readKeys(self) :
      while self.running :
         try :
            key = self.keyPress.getChar(blocking=True)
            { 'q': self.quit, #sys.exit,
              '': self.quit, #sys.exit,
              'c': self.configure,
              'h': self.help,
              'l': self.drawLine,
              'm': self.dispMode,
              'p': self.pause,
              '1': lambda : self.setVerbosity(key),
              '2': lambda : self.setVerbosity(key),
              '3': lambda : self.setVerbosity(key),
              '4': lambda : self.setVerbosity(key),
              '5': lambda : self.setVerbosity(key),
              '6': lambda : self.setVerbosity(key),
              '7': lambda : self.setVerbosity(key),
              '8': lambda : self.setVerbosity(key),
              '9': lambda : self.setVerbosity(key),
              }[key]()
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "key %s not understood.  Press \"h\" for help" % key
               
   def setVerbosity(self, verbosity) :
      self.verbosity = verbosity
      print "Verbosity is now %s" % self.verbosity

   def printLostUpdates(self):
      banner = "\nHit any key to resume.  Updates lost: 0"
      sys.stdout.write(banner)
      sys.stdout.flush()
      numPrintedChars=1
      while True:
         sleep(1)
         c= self.keyPress.getChar(blocking=False)
         if c == "":
            strg = ""
            for i in range(numPrintedChars) :
               strg += "\b"
            strg = "%s%d" % (strg,self.numLostUpdates)
            numPrintedChars = len(strg)-numPrintedChars
            sys.stdout.write(strg)
            sys.stdout.flush()
         else:
            print
            break

   def help(self) :
      usage = """
      c   : configure/start/stop ping batch menu
      h   : help
      l   : draw line now
      m   : print mode
      p   : pause
      q   : quit
      1-9 : verbosity (1 is low, 9 is high)
      """
      self.stop()
      print "  Current verbosity:  %s" % self.verbosity
      print usage
      self.printLostUpdates()
      self.start()

   
   ## Submenus for configure
   def configNodeIDs(self):
      configNodeIDsMenu = """
      Enter nodeIDs to ping.
      c : current set of nodes %s
      or nodeIDs separate by spaces
      >> """ %(str(self.nodeIDs))
      while True :
         try :
            nodeIDsStr = raw_input(configNodeIDsMenu)
            nodeIDsStrList = nodeIDsStr.split()
            if (nodeIDsStrList[0] == 'c'):
               nodeIDs = self.nodeIDs
               break
            else:
               nodeIDs = map(int,nodeIDsStrList)
               errorCheck = map(lambda x : x > 0 and x <= 65534, nodeIDs)
               if ('False' in errorCheck):
                  print "One or more of the entered nodeIDs are out of range"
               else:
                  break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be an integer value.  You input: %s" %(nodeIDsStr)
      return nodeIDs

   def configNumPing(self):
      configNumPingMenu = """
      Enter Number of Pings.
      c : current setting (%d)
      -1 : infinite loop
      or a number
      >> """ %(self.numPing)
      while True :
         try :
            numPingStr = raw_input(configNumPingMenu)
            if (numPingStr == 'c'):
               numPing = self.numPing
            else:
               numPing = int(numPingStr)
            break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be an integer value.  You input: %s" %(numPingStr)
      return numPing
   
   def configTimeout(self):
      configTimeoutMenu = """
      Enter Timeout.
      c : current setting (%.2f)
      or a number
      >> """ %(self.timeout)
      while True :
         try :
            timeoutStr = raw_input(configTimeoutMenu)
            if (timeoutStr == 'c'):
               timeout = self.timeout
               break
            else:
               timeout = float(timeoutStr)
            if not ((timeout >= self.minTimeout) and
                    (timeout <= self.maxTimeout)):
               print("Your entered value is out of range [%d,%d]"
                     %(self.minTimeout, self.maxTimeout))
            else:
               break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be an integer value.  You input: %s" %(timeoutStr)
      return timeout

   def configDelay1(self):
      configDelay1Menu = """
      Enter Delay between pinging different nodes.
      c : current setting (%.2f)
      or a number
      >> """ %(self.delay1)
      while True :
         try :
            delay1Str = raw_input(configDelay1Menu)
            if (delay1Str == 'c'):
               delay1 = self.delay1
               break
            else:
               delay1 = float(delay1Str)
            if not ((delay1 >= self.minDelay1) and
                    (delay1 <= self.maxDelay1)):
               print("Your entered value is out of range [%d,%d]"
                     %(self.minDelay1, self.maxDelay1))
            else:
               break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be an integer value.  You input: %s" %(delay1Str)
      return delay1

   def configDelay2(self):
      configDelay2Menu = """
      Enter Delay between rounds of ping
      (ping sequence number increases on each round)
      c : current setting (%.2f)
      or a number
      >> """ %(self.delay2)
      while True :
         try :
            delay2Str = raw_input(configDelay2Menu)
            if (delay2Str == 'c'):
               delay2 = self.delay2
               break
            else:
               delay2 = float(delay2Str)
            if not ((delay2 >= self.minDelay2) and
                    (delay2 <= self.maxDelay2)):
               print("Your entered value is out of range [%d,%d]"
                     %(self.minDelay2, self.maxDelay2))
            else:
               break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be an integer value.  You input: %s" %(delay2Str)
      return delay2

   def cfgTopMenu(self):
      configTopMenu = """
      Current Setting for next ping batch is
         nodeIDs = %s
         numPing = %d
         timeout = %.2f
         delay1 = %.2f (delay between pinging different nodes)
         delay2 = %.2f (delay between rounds of ping)
      Menu options:
      (all config settings apply to the next ping batch)
      s : start next ping batch (will quit current one)
      x : stop current ping batch
      n : configure nodeIDs to ping
      p : configure number of pings
      t : configure timeout for each ping
      1 : configure delay1
      2 : configure delay2
      q : exit menu
      """ %(self.nodeIDs, self.numPing, self.timeout,
            self.delay1, self.delay2)
      return configTopMenu

   def configure(self) :
      """
      Prompts for and reads in configurations for latency ping
      batches.
      """
      self.stop()
      newPing = False
      stopPing = False
      while True : # Getting Main Menu input
         print self.cfgTopMenu()
         try :
            key = self.keyPress.getChar(blocking=True)
            if key == 's':
               print "starting new latency ping batch"
               newPing = True
               break
            if key == 'x':
               print "stopping current latency ping batch"
               stopPing = True
               break
            if key == 'n':
               self.nodeIDs = self.configNodeIDs()
               continue
            if key == 'p':
               self.numPing = self.configNumPing()
               continue
            if key == 't':
               self.timeout = self.configTimeout()
               continue
            if key == '1':
               self.delay1 = self.configDelay1()
               continue
            if key == '2':
               self.delay2 = self.configDelay2()
               continue
            if key == 'q':
               print " exiting configure menu ..."
               break
            else :
               print "key %s not understood." % key
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "key %s not understood." % key

      if (newPing or stopPing):
         self.runLatThread = False
      if newPing:
         self.latencyTest(self.nodeIDs, self.numPing, self.timeout,
                          self.delay1, self.delay2)
      self.start()
      
   def drawLine(self) :
      print "  ---------------  "

   def dispMode(self) :
      print("Check in configure for settings for the next latency ping batch")
      if self.runLatThread:
         print ("Latency Thread Still Running")
      else:
         print ("Latency Thread has stopped (or will quit soon)")
   
   def pause(self) :
      self.stop()
      self.printLostUpdates()
      self.start()

   def start(self) :
      self.outputFlag = True

   def stop(self) :
      self.outputFlag = False
      self.numLostUpdates = 0

   def quit(self) :
      '''
      Quit Application.  Stops Latency Thread, Stops message
      processing thread and returns the python prompt.
      '''
      self.outputFlag = False
      self.runLatThread = False
      self.running = False


##### Main Code #####

## Instantiate your own Comm object and connection
# import pytos.Comm as Comm
# recvComm = Comm.Comm
# recvComm.connect("sf@localhost:9001")

## Uses the comm object instantiated by app
if (appType == 'TestDetectionEvent'):
   recvComm = app.rpc.receiveComm # drain comm
   sendComm = Comm.getCommObject(app)
else: # assume 'MetricsMote'
   recvComm = Comm.getCommObject(app) # ex. app.connections[0]
   sendComm = recvComm

metricsMsg = app.msgs.MetricsCmdMsg
mLat = MetricsLatency(sendComm,recvComm,appType)
mLat.readKeys()
