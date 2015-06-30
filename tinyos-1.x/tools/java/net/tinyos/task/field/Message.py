from array import *
from config import config

class Message:
  MSG_SIZE = config.msg_size
  BCAST = 0xffff
  addr = 0
  type = 2
  group = 3
  length = 4
  data = 5
  
  def __init__(self, msg=None):
    if msg is None:
      self.msg = array('B', [0]*Message.MSG_SIZE)
      self.set8(config.group, Message.group)
    elif isinstance(msg, Message):
      self.msg = msg.msg
    else:
      self.msg = array('B', msg)

  def tostring(self):
    return self.msg.tostring()

  def setoffset(self, offset):
    if offset != None:
      self.offset = offset
      
  def set8(self, n, offset=None):
    if offset == None:
      offset = self.offset
    self.offset = offset + 1
    self.msg[offset] = n & 0xff
    return self

  def getu8(self, offset=None):
    if offset == None:
      offset = self.offset
    self.offset = offset + 1
    return self.msg[offset]

  def geti8(self, offset=None):
    x = self.getu8(offset)
    if (x >= 128):
      x = x - 256
    return x
  
  def set16(self, n, offset=None):
    self.set8(n & 0xff, offset)
    self.set8((n >> 8) & 0xff)
    return self

  def getu16(self, offset=None):
    val = self.getu8(offset)
    val = val | self.getu8() << 8
    return val

  def geti16(self, offset=None):
    x = self.getu16(offset)
    if (x >= 32768):
      x = x - 65536
    return x

  def setstring(self, s, offset=None):
    self.setoffset(offset)
    for i in range(0, len(s)):
      self.set8(ord(s[i]))
    self.set8(0)

  def getstring(self, offset=None):
    self.setoffset(offset)
    chars = array('B')
    c = self.getu8()
    while c != 0:
      chars.append(c)
      c = self.getu8()
    return chars.tostring()
  
  def prt(self):
    for i in range(0, Message.MSG_SIZE):
      print '%02x' % self.msg[i],
    print
