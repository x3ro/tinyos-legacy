from pickle import *

class Config:
  def __init__(self):
    self.local_id = 0x64
    self.group = 0x2a
    self.msg_size = 56

    self.use_ip = 0;
    self.sf_host = "/dev/tts/0"
    self.sf_port = 57600

    self.send_period = 500
    self.send_count = 3
    self.wakeup_period = 6000
    self.mote_timeout = 10000

try:
  cf = open("field.config")
  config = load(cf)
  cf.close()
except:
  config = Config()
