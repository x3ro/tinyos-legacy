# Functions for interacting with TestDetectionEvent nodes
   
from __main__ import app
from time import sleep

TDtimeout = 5
def detectMode(mode='UVA', detectAddr=65534):
   """ switch the mote event generation mode.

   Valid modes are 'UVA', 'simple', 'userbutton', 'timer'
   """
   
   print '>>>>> app.RegistryC.DetectionEventAddr.set(%d)' %(detectAddr)
   print app.RegistryC.DetectionEventAddr.set(detectAddr, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.DummyDetectionTimer.set(0)'
   print app.RegistryC.DummyDetectionTimer.set(0, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.PirSampleTimer.set(0)'
   print app.RegistryC.PirSampleTimer.set(0, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.UserButtonEventEnable.set(0)'
   print app.RegistryC.UserButtonEventEnable.set(0, timeout=TDtimeout)
   sleep(0.1)
   
   if mode == 'UVA':
      # switch to 3 stage detection code
      # add quelling/damping to report
      print '>>>>> app.PIRDetectFilterM.PIRDetectEnabled.poke(1)'
      print app.PIRDetectFilterM.PIRDetectEnabled.poke(1, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.PIRSimpleThreshEventM.PIRSimpleThreshEnabled.poke(0)'
      print app.PIRSimpleThreshEventM.PIRSimpleThreshEnabled.poke(0, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.RegistryC.PirSampleTimer.set(102)'
      print app.RegistryC.PirSampleTimer.set(102, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.RegistryC.PIRDampTimer.set(2*1024)'
      print app.RegistryC.PIRDampTimer.set(2*1024, timeout=TDtimeout)
      sleep(0.1)
   elif mode == 'simple':
      print '>>>>> app.PIRDetectFilterM.PIRDetectEnabled.poke(0)'
      print app.PIRDetectFilterM.PIRDetectEnabled.poke(0, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.PIRSimpleThreshEventM.PIRSimpleThreshEnabled.poke(1)'
      print app.PIRSimpleThreshEventM.PIRSimpleThreshEnabled.poke(1, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.RegistryC.PirSampleTimer.set(102)'
      print app.RegistryC.PirSampleTimer.set(256, timeout=TDtimeout)
      sleep(0.1)
      print '>>>>> app.RegistryC.PIRRawThresh.set(2700)'
      print app.RegistryC.PIRRawThresh.set(4050, timeout=TDtimeout)
      sleep(0.1)
   elif mode == 'userbutton':
      print '>>>>> app.RegistryC.UserButtonEventEnable.set(1)'
      print app.RegistryC.UserButtonEventEnable.set(1, timeout=TDtimeout)
      sleep(0.1)
   elif mode == 'timer':
      print '>>>>> app.RegistryC.DummyDetectionTimer.set(1000)'
      print app.RegistryC.DummyDetectionTimer.set(1000, timeout=TDtimeout)
      sleep(0.1)



def initDetect():
   """ Switching to 3 stage detection code after startup of a node.

       Sends less packets than detectMode.  Meant for changing nodes that
       have just booted up.
   """
   global app
   
   print '>>>>> app.RegistryC.DetectionEventAddr.set(app.enums.TOS_BCAST_ADDR)'
   print app.RegistryC.DetectionEventAddr.set(app.enums.TOS_BCAST_ADDR, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.DummyDetectionTimer.set(0)'
   print app.RegistryC.DummyDetectionTimer.set(0, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.PirSampleTimer.set(102)'
   print app.RegistryC.PirSampleTimer.set(102, timeout=TDtimeout)
   sleep(0.1)
   print '>>>>> app.RegistryC.PIRDampTimer.set(2*1024)'
   print app.RegistryC.PIRDampTimer.set(2*1024, timeout=TDtimeout)
   sleep(0.1)



def queryDetect(*moteIDs):
   """Queries basic detection parameters of the motes.
      If no moteID given, queries all motes.
   """

   if len(moteIDs) == 0:
      print('>>>>> app.RegistryC.PirSampleTimer.get()')
      print app.RegistryC.PirSampleTimer.get(timeout=TDtimeout)
      sleep(0.1)
      print('>>>>> app.PIRDetectFilterM.PIRDetectEnabled.peek()')
      print app.PIRDetectFilterM.PIRDetectEnabled.peek(timeout=TDtimeout)
      sleep(0.1)
   else:
      for mote in moteIDs:
         print('>>>>> app.RegistryC.PirSampleTimer.get(address=%d)' %(mote))
         print app.RegistryC.PirSampleTimer.get(address=mote, timeout=TDtimeout)
         sleep(0.1)
         print('>>>>> app.PIRDetectFilterM.PIRDetectEnabled.peek(address=%d)'
               %(mote))
         print app.PIRDetectFilterM.PIRDetectEnabled.peek(address=mote,
                                                          timeout=TDtimeout)
         sleep(0.1)


def queryCount(*moteIDs):
   """Queries for the DetectionEvent packet counter of the motes.
      If no moteID given, queries all motes.
   """
   if len(moteIDs) == 0:
      print('>>>>> app.DetectionEventM.counter.peek()')
      print app.DetectionEventM.counter.peek(timeout=TDtimeout)
   else:
      for mote in moteIDs:
         print('>>>>> app.DetectionEventM.counter.peek(address=%d)' %(mote))
         print app.DetectionEventM.counter.peek(address=mote, timeout=TDtimeout)
         sleep(0.1)
