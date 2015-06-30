# Monitoring tools for interacting with MetricsMote and TestDetectionEvent
# with the KrakenMetrics module
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
#       from MetricsMonitor import *
# -- Option II --
# 2) Start up PyTOS using MetricsShell.py
# 3) Interact with Program via keypresses
#
# See nestfe/nesc/apps/MetricsTools for more details
# See also nestfe/scripts/metrics/sh for startup examples
#
# KNOWN LIMITATIONS :
# * The queue sizes of the various threads put a limit on the rates with
#   which the thread poll.  Particularly, you should check that the size
#   of monQ is adequate for slow polling rates.
#
# IMPLEMENTATION:
# For MetricsMonitor, the general message handling flow is:
# 1) messages arrive and are processed by the message handling thread
#    running processMessages().  Messages are distributed to the
#    monitoring thread through monQ.
# 2) the monitoring thread processes the messages and outputs to the
#    screen.  The user can supress/configure the output by typing at
#    the console.



import os, sys
import threading
from Queue import Queue
from time import sleep, time

#Pytos stuff
from __main__ import app
from __main__ import appType
import pytos.Comm as Comm
from pytos.Comm import MessageQueue
import pytos.util.KeyPress as KeyPress

##### See bottom of file for executed code when module is imported #####


#################### External Functions ####################
class MetricsMonitor( object ):

   def __init__(self,sendComm,recvComm,appType="MetricsMote"):
      """
      Creation of MetricsMonitor object to allow background thread processing.
        appType - Flag to determine how to parse messages
                  (MetricsMote, TestDetectionEvent)
        recvComm - Comm object for receiving messages
        sendComm - Comm object for sending messages
      """

      self.appType = appType # for debugging

      ## Display Configurations
      print "\nType \"h\" for help\n"
      self.keyPress = KeyPress.KeyPress()
      self.verbosity = '4'
      self.numLostUpdates = 0
      self.outputFlag = True

      ## Monitor Thread
      self.monQ = Queue(1000) # large to be safe
      # Data Structure
        # all dictionaries use nodeID for keys
        # monTable entries: [seqNo,timeStamp]
        # monStats entries: list of [numReply,numSent,succRate]
        # monPrev entries: previously seen sequence number
      self.monTable = {}
      self.monStats = {}
      self.monPrevSeqNo = {}
      # updateType - 'time' or 'pkts'
      #               'pkts' means we wait to receive updatePeriod number
      #               of recognized pkts before reporting
      # updatePeriod - number of seconds or number of packets
      #                between updating statistics
      self.updateType ='time'
      self.updatePeriod = 2
      self.minPeriod = 0.1 # limits for updatePeriod
      self.maxPeriod = 10 # limits for updatePeriod
      self.running = True
      self.forceContinue = False # Used to force pkt updates to not wait on monQ
      self.monSemaphore = threading.Semaphore()
      monThread = threading.Thread(target=self.processRates,
                                   args=())
      monThread.setDaemon(True)
      monThread.start()

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

      
   ##### Threading and Processing Code #####
   def processMessages(self,msgQ):
      """
      Thread message handling code.  Message handling involves
      filtering for the proper message and distributing messages to
      the monitoring queue.

      Could eliminate monQ and make one thread, but if it ain't broke
      don't fix it.
      """
      while self.running :
         (addr,msg) = msgQ.get()
         if (((msg.amType == self.AM_METRICSREPLYMSG) and
              (msg.msgType == app.enums.MetricsTypes.CONST_REPORT_REPLY)) or
             (msg.amType == self.AM_DETECTIONEVENTMSG)):
            self.monQ.put(msg)

   def transSuccCalc(self):
      """
      Called by processRates() for calculations involving transmission
      success rate
      PRECONDITION:
      * motes send packets starting with counter/sequence number 1
      * monTable only contains packets from the last updatePeriod
      POSTCONDITION:
      self.monStats updated with
        1) transmission success rate
           * for time monitoring:
             this is calculated assuming no packets missed at the
             end of a period (these missing packets are accounted for
             at the beginning of the next period)
           * for packet monitoring:
             "sent" pkts / received pkts (see below)
           * -1 means no packets received
        2) number of packets received (for time monitoring)
        3) number of packets "sent"
           * counts the number of packets between last recorded
             sequence number and the last packet received
      """
      for nodeID in sorted(self.monTable.keys()):
            monList = sorted(self.monTable[nodeID])
            lastSeqNo = monList[len(monList)-1]
            numReply = len(monList)
            if self.monPrevSeqNo.has_key(nodeID):
               numSent = lastSeqNo - self.monPrevSeqNo[nodeID]
            else:
               numSent = lastSeqNo # assume start from 1
            if (numSent == 0):
               succRate = -1
            else:
               succRate = numReply/numSent
            self.monPrevSeqNo[nodeID] = lastSeqNo
            if self.monStats.has_key(nodeID):
               self.monStats[nodeID].append([numReply,numSent,succRate])
            else:
               self.monStats[nodeID] = [[numReply,numSent,succRate]]

   def insertMonTable(self,msg):
      """
      Performs unpacking of different message types and inserts into
      monitoring table.  Used by processRates().
      """
      if (msg.amType == self.AM_METRICSREPLYMSG):
         nodeID = msg.nodeID
         counter = msg.data # sequence number
      elif (msg.amType == self.AM_DETECTIONEVENTMSG):
         nodeID = msg.parentMsg.source
         counter = msg.count
      if self.monTable.has_key(nodeID):
         self.monTable[nodeID].append(counter)
      else:
         self.monTable[nodeID] = [counter]

   def processRates(self):
      """
      Monitor Thread code.  Monitors Packets dumped in monQ.  The
      modes of operation (updateType, updatePeriod) can change during
      execution.
        updateType - flag of "time" or "pkts" for operating mode
        updatePeriod - time/num packets between monitoring updates
      METHOD: Dumps data into a table (for consistent state), then
      processes it.  Erases previous monitoring statistics before
      proceeding.
      POSTCONDITION:
      Under 'time' monitoring mode, does not display statistics for
      last period if we stop the thread
      """
      self.monStats = {}
      startTime = time()
      while self.running:
         self.forceContinue = False
         self.monTable = {}
         self.monSemaphore.acquire() # synchronize operations
         updateType = self.updateType
         updatePeriod = self.updatePeriod
         self.monSemaphore.release() # synch

         if (updateType == "time"):
            startTime = time()
            # Dump data into a table
            pktCnt = 0
            while not self.monQ.empty():
               msg = self.monQ.get();
               self.insertMonTable(msg)
               pktCnt += 1
            recvPkts = pktCnt
            self.transSuccCalc()
            self.dispMonitor(recvPkts,updatePeriod)
            # Wait for next updatePeriod
            processTime = time() - startTime
            sleep(max(0,updatePeriod-processTime))
         elif (updateType == "pkts"):
            # Dump data into a table
            pktCnt = 0
            # allows for quitting monitoring thread if no pkts arrive
            while (self.running and (not self.forceContinue)
                  and (pktCnt <= updatePeriod)):
               try:
                  msg = self.monQ.get(True,2)
                  self.insertMonTable(msg)
                  pktCnt += 1
               except:
                  pass
            stopTime = time()
            pktWaitTime = stopTime - startTime
            startTime = stopTime
            recvPkts = pktCnt - 1
            self.transSuccCalc()
            self.dispMonitor(recvPkts,pktWaitTime)
         else:
            print "Unknown update type for monitoring: %s" %(updateType)
            break
      print "Monitoring Thread Finished."


   ##### Display Code #####
   def dispMonitor(self,recvPkts,pktWaitTime):
      """
      Displays monitoring output, based on verbosity levels.
      """
      # All verbosity levels
      transRateStr = "Transmission Rate (%d/%d) %.3f pkts/sec\n" \
                     %(recvPkts,pktWaitTime,recvPkts/pktWaitTime)
      separatorStr = "******************************\n"
      if (int(self.verbosity) > 5):
         for nodeID,val in self.monStats.iteritems():
            recentStat = val[len(val)-1]
            (numReply,numSent,succRate) = recentStat
            transSuccStr = transSuccStr + \
                           "Node: %d  success rate %d/%d (%d %%)\n" \
                           %(nodeID,numReply,numSent,succRate*100)
      else:
         transSuccStr = ""
      # Display Output
      dispStr = transSuccStr + separatorStr + transRateStr
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
      c   : configure
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

   def configure(self) :
      """
      Prompts for and reads in user values for update type and update
      period.
      """
      configTypeMenu = """
      Enter Update Type:
      0 : current setting (%s)
      1 : \'time\'
      2 : \'pkts\'
      """ %(self.updateType)
      configPeriodMenu = """
      Current Period is %d
      Enter Update Period (secs, 0 for current period):
      """ %(self.updatePeriod)
      self.stop()
      print configTypeMenu
      while True : # Getting Type input
         try :
            key = self.keyPress.getChar(blocking=True)
            if key == '0':
               print "keeping current update type"
               updateType = self.updateType
               break
            if key == '1':
               print "\'time\' update type selected"
               updateType = 'time'
               break
            if key == '2':
               print "\'pkts\' update type selected"
               updateType = 'pkts'
               break
            else :
               print "key %s not understood." % key
               print configTypeMenu
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "key %s not understood." % key
            print configTypeMenu
      while True : # Getting Period input
         try :
            updatePeriodStr = raw_input(configPeriodMenu)
            updatePeriod = float(updatePeriodStr)
            if (updatePeriod == 0):
               updatePeriod = self.updatePeriod
            if not ((updatePeriod >= self.minPeriod) and
                    (updatePeriod <= self.maxPeriod)):
               print("Your entered value is out of range [%d,%d]"
                     %(self.minPeriod, self.maxPeriod))
            else:
               break
         except Exception, e:
            if len(e.args)>0:
               print e.args[0]
            else :
               raise
            print "Input must be a float value.  You input: %s" %(updatePeriodStr)

      # Synchronize with thread
      self.monSemaphore.acquire()
      self.updateType = updateType
      self.updatePeriod = updatePeriod
      self.monSemaphore.release()
      self.forceContinue = True
      self.start()
      
   def drawLine(self) :
      print "  ---------------  "

   def dispMode(self) :
      print ("Monitoring Mode:  Update Type %s, Update Period %d"
             %(self.updateType, self.updatePeriod))

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
      Quit Application.  Stops Monitoring Thread, Stops message
      processing thread and returns the python prompt.
      '''
      self.outputFlag = False
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
mMon = MetricsMonitor(sendComm,recvComm,appType)
mMon.readKeys()
