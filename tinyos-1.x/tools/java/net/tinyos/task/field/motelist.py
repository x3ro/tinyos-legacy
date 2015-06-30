from Message import *
from time import time
from config import config

class WakeupMsg (Message):
  sender = Message.data
  
  def __init__(self):
    Message.__init__(self)
    self.set16(Message.BCAST, Message.addr)
    self.set8(120, Message.type)
    self.set8(2, Message.length)
    self.set16(config.local_id, self.sender)

class Motelist:
  def periodic(self):
    self.comm.send(self.msg)
    self.timeoutmotes()
    self.master.after(config.wakeup_period, self.periodic)

  def __init__(self, master, comm, receiver, gui):
    self.master = master
    self.comm = comm
    self.motes = {}
    self.msg = WakeupMsg()
    self.gui = gui

    receiver.sethandler(122, self.wokeup)
    self.periodic()

  def wokeup(self, msg):
    msg = FieldReplyMsg(msg)
    sender = msg.getu16(FieldReplyMsg.sender)
    print '%d is awake' % sender
    self.awake(sender)

  def timeoutmotes(self):
    now = time()
    for mote in self.motes.keys():
      if self.motes[mote] + config.mote_timeout / 1000.0 < now:
        self.asleep(mote)
        print 'mote %d went away' % mote
        
  def awake(self, mote):
    redisplay = not self.motes.has_key(mote)
    self.motes[mote] = time()
    if redisplay:
      self.redisplay()
      
  def redisplay(self):
    self.gui.setDestinations(self.motes.keys())

  def asleep(self, mote):
    del self.motes[mote]
    self.redisplay()
    
