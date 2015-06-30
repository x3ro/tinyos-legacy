from Message import *
from Comm import *
from random import *
from config import config

seed()

class FieldMsg (Message):
  sender = Message.data
  cmdId = Message.data + 2
  cmd = Message.data + 4

  def __init__(self, dest, cmd):
    Message.__init__(self)
    self.set16(dest, Message.addr)
    self.set8(121, Message.type)
    self.set16(config.local_id, self.sender)
    self.setstring(cmd, self.cmd)

class FieldReplyMsg (Message):
  sender = Message.data + 0
  cmdId = Message.data + 2
  error = Message.data + 4
  response = Message.data + 6
  
  def __init__(self, msg):
    Message.__init__(self, msg)


class Command:
  def __init__(self, master, comm, receiver, motelist):
    self.comm = comm
    self.master = master
    self.motelist = motelist
    self.cmdid = int(random() * 65536)
    self.commands = {}
    self.sending = []
    receiver.sethandler(122, self.fieldreply)

  def fieldreply(self, msg):
    msg = FieldReplyMsg(msg)
    sender = msg.getu16(FieldReplyMsg.sender)
    self.motelist.awake(sender)

    cmdId = msg.getu16(msg.cmdId)
    if cmdId != 0:
      try:
        self.commands[cmdId](sender, msg)
      except KeyError:
        print "unknown command " + `cmdId`

  def sendn(self, msg, count):
    if self.sending == []:
      self.master.after(config.send_period, self.sendnext)
    self.sending.extend([ msg ] * count)

  def sendnext(self):
    self.comm.send(self.sending[0])
    del self.sending[0]
    if self.sending != []:
      self.master.after(config.send_period, self.sendnext)

  def send(self, msg, replyhandler):
    size = msg.offset - Message.data
    msg.set8(size, msg.length)
    msg.set16(self.cmdid, msg.cmdId)
    self.commands[self.cmdid] = replyhandler
    self.cmdid = self.cmdid + 1
    self.sendn(msg, config.send_count)
    #self.comm.send(msg)

class SimpleCommand:
  def __init__(self, comm):
    self.comm = comm

  def result(self, response):
    return "done"

  def run(self, dest, output):
    def receive(sender, response, self=self, output=output):
      output.add(sender, self.result(response))
    self.comm.send(self.cmd(dest), receive)
  

class Green (SimpleCommand):
  name = "green"
  def cmd(self, dest):
    return FieldMsg(dest, "SetLedG").set8(2)

class Beep (SimpleCommand):
  name = "beep"
  def cmd(self, dest):
    return FieldMsg(dest, "SetSnd").set16(500)
    
class Reset (SimpleCommand):
  name = "reset"
  def cmd(self, dest):
    return FieldMsg(dest, "Reset")
    
class Ping (SimpleCommand):
  name = "ping"

  def result(self, response):
    response.setoffset(FieldReplyMsg.response)
    parent = response.getu16()
    freeram = response.getu16()
    voltage = response.getu16()
    if voltage != 0:
      voltage = 0.58 * 1024.0 / voltage
    qlen = response.getu8()
    mhqlen = response.getu8()
    depth = response.getu8()
    qual = response.getu8()
    qid1 = response.getu8()
    qid2 = response.getu8()
    return "%.1fV Parent %d, RAM %d, qln %d, mhq %d, dpth %d, qual %d, q1 %d, q2 %d" % (voltage, parent, freeram, qlen, mhqlen, depth, qual, qid1, qid2)
  
  def cmd(self, dest):
    return FieldMsg(dest, "Ping")
