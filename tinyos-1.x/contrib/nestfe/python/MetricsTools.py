# Generic tools for interacting with MetricsMote and TestDetectionEvent
# with the KrakenMetrics module
#
# USAGE:
# 1) setup your PYTHONPATH to include the directory containing
#    this file
# -- Option I --
# 2a) Start PyTOS using PytosShell.py
# 2b) assign appType appropriately at the console
#       Valid options are: "TestDetectionEvent", "MetricsMote"
#       (see bottom of file for details)
# 2c) at the PyTOS command prompt type
#       from MetricsTools import *
# -- Option II --
# 2) Start up PyTOS using MetricsShell.py
# 3) Call the external functions in this file
#
# See nestfe/nesc/apps/MetricsTools for more details
# See also nestfe/scripts/metrics/sh for startup examples
#
# KNOWN LIMITATIONS :
# * Since Timestamping is done entirely on the mote, it is difficult
#   to get timestamps using different motes.
# * To not step on the ping sequence numbers used by MetricsLatency, the
#   sequence numbers used by ping are > 10000.
#
# Timestamping is done entirely on the mote.  2^(32-15)/60*60 = 36 hours
# before the counter on the mote wraps around (32 bit counter, 1/2^15
# seconds per counter increment)


import os, sys
import threading
from Queue import Queue
from time import sleep, time #clock was initially for timestamping

#Pytos stuff
from __main__ import app
from __main__ import appType
import pytos.Comm as Comm
from pytos.Comm import MessageQueue

##### See bottom of file for executed code when module is imported #####


#################### External Functions ####################

def ping(seqNo,addr=app.enums.TOS_BCAST_ADDR):
   """
   Sends a Ping packet to a mote and waits for the response
     seqNo - the sequence number for matching a ping response
   USAGE NOTE: All ping sequence number will have 10000 added to them
               and limited to the range [10000, 0xffff] to avoid
               conflict with MetricsLatency.
   """
   seqNo = (seqNo % (0xffff - 10000)) + 10000
   print "The new ping seqNo used is %d" %(seqNo)
   metricsMsg.cmd = app.enums.MetricsTypes.PING
   metricsMsg.data = seqNo
   sendComm.send(addr,metricsMsg)

def setTransmitRate(rate,addr=app.enums.TOS_BCAST_ADDR):
   """
   Sets the mote constant transmit rate
     rate  -  the period between samples, in binary milliseconds
     
   For TestDetectionEvent, only changes the timer fire rate, but does
   not enable constant reports.
   """
   if (appType == "MetricsMote"):
      metricsMsg.cmd = app.enums.MetricsTypes.SET_TRANSMIT_RATE
      metricsMsg.data = rate
      sendComm.send(addr,metricsMsg)
   elif (appType == "TestDetectionEvent"):
      app.RegistryC.DummyDetectionTimer.set(rate,address=addr)
   else:
      print "appType not recognized %s" %(appType)

   
def getTransmitRate(addr=app.enums.TOS_BCAST_ADDR):
   """
    Gets the constant transmit rate on the mote
   """
   if (appType == "MetricsMote"):
      metricsMsg.cmd = app.enums.MetricsTypes.GET_TRANSMIT_RATE
      sendComm.send(addr,metricsMsg)
   elif (appType == "TestDetectionEvent"):
      app.RegistryC.DummyDetectionTimer.get(address=addr)
   else:
      print "appType not recognized %s" %(appType)

def resetCounter(addr=app.enums.TOS_BCAST_ADDR):
   """
   Resets the counter used for constant transmissions
   """
   if (appType == "MetricsMote"):
      metricsMsg.cmd = app.enums.MetricsTypes.RESET_COUNT
      sendComm.send(addr,metricsMsg)
   elif (appType == "TestDetectionEvent"):
      app.DetectionEventM.counter.poke(0,address=addr)
   else:
      print "appType not recognized %s" %(appType)

def getCounter(addr=app.enums.TOS_BCAST_ADDR):
   """
   Gets the counter used for constant transmissions
   """
   if (appType == "MetricsMote"):
      metricsMsg.cmd = app.enums.MetricsTypes.GET_COUNT
      sendComm.send(addr,metricsMsg)
   elif (appType == "TestDetectionEvent"):
      app.DetectionEventM.counter.peek(address=addr)
   else:
      print "appType not recognized %s" %(appType)

def setRadioPower(RFpower,addr=app.enums.TOS_BCAST_ADDR):
   """
   Set the mote radio power
     RFpower - the radio power level (31 highest, 3 lowest)
   """
   if (RFpower > app.enums.MetricsTypes.MAX_RF_POWER) or \
      (RFpower < app.enums.MetricsTypes.MIN_RF_POWER):
      print("RF power out of range [3,31].  RF power = %d" %(RFpower))
   else:
      if (appType == "MetricsMote"):
         metricsMsg.cmd = app.enums.MetricsTypes.SET_RF_POWER
         metricsMsg.data = RFpower
         sendComm.send(addr,metricsMsg)
      elif (appType == "TestDetectionEvent"):
         app.rpc.KrakenMetricsM.RemoteRadioControl.SetRFPower(RFpower,address=addr)
      else:
         print "appType not recognized %s" %(appType)

      
def getRadioPower(addr=app.enums.TOS_BCAST_ADDR):
   """
   Get the mote radio power
   """
   if (appType == "MetricsMote"):
      metricsMsg.cmd = app.enums.MetricsTypes.GET_RF_POWER
      sendComm.send(addr,metricsMsg)
   elif (appType == "TestDetectionEvent"):
      app.rpc.KrakenMetricsM.RemoteRadioControl.GetRFPower(address=addr)
   else:
      print "appType not recognized %s" %(appType)

def getCounters(nodeList):
   """
   Query a list of nodes for their current Counter values
   """
   for nodeID in nodeList:
      if (appType == "MetricsMote"):
         metricsMsg.cmd = app.enums.MetricsTypes.GET_COUNT
         sendComm.send(nodeID,metricsMsg)
      elif (appType == "TestDetectionEvent"):
         app.DetectionEventM.counter.peek(address=nodeID)
      else:
         print "appType not recognized %s" %(appType)
         break
      sleep(0.5)

#################### Internal Functions ####################

class MetricsTools( object ):

   def __init__(self,sendComm,recvComm,appType="MetricsMote"):
      """
      Creation of MetricsTools object to allow background thread processing.
        appType - Flag to determine how to parse messages
                  (MetricsMote, TestDetectionEvent)
        recvComm - Comm object for receiving messages
        sendComm - Comm object for sending messages
      """

      self.appType = appType # for debugging

      ## Message Handling
      msgQ = MessageQueue(10);

      recvComm.register(app.msgs.MetricsReplyMsg, msgQ)
      self.AM_METRICSREPLYMSG = app.enums.MetricsTypes.AM_METRICSREPLYMSG
      if (appType == "TestDetectionEvent"):
         # recvComm is a drain connection
         recvComm.register(app.msgs.DetectionEventMsg, msgQ)
         self.AM_DETECTIONEVENTMSG = app.enums.AM_DETECTIONEVENTMSG
      else: # assume appType == MetricsMote
         self.AM_DETECTIONEVENTMSG = None

      msgThread = threading.Thread(target=self.processMessages,
                                   args=(msgQ,))
      msgThread.setDaemon(True)
      msgThread.start()

     
   ##### Internal Code #####
   def processMessages(self,msgQ):
      """
      Thread message handling code.  Messages handling includes printing
      notifications to the screen.
      """
      while True :
         (addr,msg) = msgQ.get()
         if (msg.amType == self.AM_METRICSREPLYMSG):
            if (msg.msgType == app.enums.MetricsTypes.PING_REPLY):
               if (msg.data > 10000):
                  tDelta = float(((msg.tsReply - msg.tsSend) % 0xffffffff) >> 5)
                  print("Ping Response Time for node %d, SeqNo %d:  %.2f ms"
                        %(msg.nodeID,msg.data,tDelta))
            elif (msg.msgType == app.enums.MetricsTypes.CONST_REPORT_REPLY):
               pass
            elif (msg.msgType == app.enums.MetricsTypes.COUNT_REPLY):
               print("Current Counter Value for node %d:  %d\n"
                     %(msg.nodeID,msg.data))
            elif (msg.msgType == app.enums.MetricsTypes.TRANS_RATE_REPLY):
               print("Constant transmission rate for node %d:  %d\n"
                     %(msg.nodeID,msg.data))
            elif (msg.msgType == app.enums.MetricsTypes.RF_POWER_REPLY):
               print("RF power level for node %d:  %d\n"
                     %(msg.nodeID,msg.data))
         elif (msg.amType == self.AM_DETECTIONEVENTMSG):
            pass
         else:
            print("MetricsTools.py: registered for a message you are not processing.  AM Type: %d" %(msg.amType))


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
mTool = MetricsTools(sendComm,recvComm,appType)
