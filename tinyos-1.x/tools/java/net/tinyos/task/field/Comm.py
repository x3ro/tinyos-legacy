from os import *
from termios import *
from socket import *
from Message import *
from errno import *
from fcntl import *
try:
  from FCNTL import *
except:
  pass
from select import *

class IPComm:
  def __init__(self, host, port):
    self.fd = socket(AF_INET, SOCK_STREAM)
    self.fd.connect((gethostbyname(host), port))

  def send(self, msg):
    #msg.prt()
    msg = msg.tostring()
    assert len(msg) == Message.MSG_SIZE
    self.fd.setblocking(1)
    self.fd.send(msg)

  def recv(self):
    self.fd.setblocking(0)
    try:
      msg = self.fd.recv(Message.MSG_SIZE)
    except:
      return
    if len(msg) < Message.MSG_SIZE:
      self.fd.setblocking(1)
      msg = msg + self.fd.recv(Message.MSG_SIZE - len(msg))
    return Message(msg)

class SerComm:
  timeout = 0.01

  def __init__(self, dev, baud):
    if baud == 57600:
      baudrate = B57600
    else:
      baudrate = B19200
    self.fd = open(dev, O_RDWR | O_NOCTTY)
    tcflush(self.fd, TCIFLUSH)
    attr = tcgetattr(self.fd)
    attr[0] = IGNPAR | IGNBRK
    attr[1] = 0
    attr[2] = CS8 | CLOCAL | CREAD
    attr[3] = 0
    attr[4] = baudrate
    attr[5] = baudrate
    tcsetattr(self.fd, TCSANOW, attr)

  def send(self, msg):
    #msg.prt()
    msg = msg.tostring()
    assert len(msg) == Message.MSG_SIZE
    fcntl(self.fd, F_SETFL, 0)
    write(self.fd, msg)

  def readone(self):
    try:
      char = read(self.fd, 1)
    except OSError, err:
      if err[0] == EAGAIN:
        return
      else:
        raise
    return char

  def readone_delay(self):
    ready = select([ self.fd ], [], [], self.timeout)
    if ready[0] != []:
      return read(self.fd, 1)
    else:
      return

  def recv(self):
    fcntl(self.fd, F_SETFL, O_NONBLOCK)
    while 1: # find 0x7e 0x00
      while 1: # find 0x7e, exit if no chars
        addr1 = self.readone()
        if addr1 == None:
          return
        if addr1 == '\x7e':
          break
      # wait for 0x00
      addr2 = self.readone_delay()
      if addr2 == None:
        return
      if addr2 == '\0':
        break
    # We have a header, try and get the whole message
    msg = addr1 + addr2
    for i in range(0, Message.MSG_SIZE - len(msg)):
      char = self.readone_delay()
      if char == None:
        return
      msg = msg + char
    return Message(msg)

class Receiver:
  def periodic(self):
    msg = self.comm.recv()
    while msg:
      self.dispatch(msg)
      msg = self.comm.recv()
    self.master.after(200, self.periodic)

  def __init__(self, master, comm):
    self.master = master
    self.comm = comm
    self.handlers = {}
    self.periodic()

  def sethandler(self, type, fn):
    self.handlers[type] = fn

  def dispatch(self, msg):
    type = msg.getu8(Message.type)
    if self.handlers.has_key(type):
      self.handlers[type](msg)
    else:
      print "Unknown message: ",
      msg.prt()
