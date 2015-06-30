# This script is in the public domain and has no copyright
#
# This is a silly little example script that makes for a fun demo

from simcore import *
from simutil import *
import simtime
from net.tinyos.sim.event import *

step = 5

def next_mote():
  global n
  ret = motes[n]
  n += 1
  return ret

def T(x, y):
  motemover.moveTo(next_mote(), step, x,      y, arrived)
  motemover.moveTo(next_mote(), step, x + 4,  y, arrived)
  motemover.moveTo(next_mote(), step, x + 8,  y, arrived)
  motemover.moveTo(next_mote(), step, x + 4,  y + 5, arrived)
  motemover.moveTo(next_mote(), step, x + 4,  y + 10, arrived)
  motemover.moveTo(next_mote(), step, x + 4,  y + 15, arrived)

def Y(x, y):
  motemover.moveTo(next_mote(), step, x,      y, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y, arrived)
  motemover.moveTo(next_mote(), step, x + 3,  y + 2, arrived)
  motemover.moveTo(next_mote(), step, x + 7,  y + 2, arrived)
  motemover.moveTo(next_mote(), step, x + 5,  y + 6, arrived)
  motemover.moveTo(next_mote(), step, x + 5,  y + 10, arrived)
  motemover.moveTo(next_mote(), step, x + 5,  y + 15, arrived)

def H(x, y):
  motemover.moveTo(next_mote(), step, x,      y, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 4, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 7, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 11, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 15, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 4, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 7, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 11, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 15, arrived)
  motemover.moveTo(next_mote(), step, x + 3, y + 7, arrived)
  motemover.moveTo(next_mote(), step, x + 7, y + 7, arrived)

def O(x, y):
  motemover.moveTo(next_mote(), step, x + 2,  y, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 4, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 7, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 11, arrived)
  motemover.moveTo(next_mote(), step, x + 2,  y + 15, arrived)

  motemover.moveTo(next_mote(), step, x + 8,  y, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 4, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 7, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 11, arrived)
  motemover.moveTo(next_mote(), step, x + 8,  y + 15, arrived)

  motemover.moveTo(next_mote(), step, x + 5, y, arrived)
  motemover.moveTo(next_mote(), step, x + 5, y + 15, arrived)

def N(x, y):
  motemover.moveTo(next_mote(), step, x,      y, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 4, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 7, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 11, arrived)
  motemover.moveTo(next_mote(), step, x,      y + 15, arrived)

  motemover.moveTo(next_mote(), step, x + 10, y, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 4, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 7, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 11, arrived)
  motemover.moveTo(next_mote(), step, x + 10, y + 15, arrived)

  motemover.moveTo(next_mote(), step, x + 2, y + 3, arrived)
  motemover.moveTo(next_mote(), step, x + 5, y + 7, arrived)
  motemover.moveTo(next_mote(), step, x + 7, y + 11, arrived)

# when the mote arrives, boot it with a one second jitter
def arrived(mote):
  CallIn(simcore.random.nextInt(simtime.onesec), mote.turnOn)

def stop():
  for mote in motes:
    try:
      motemover.stop(mote)
    except:
      pass
    
def TYTHON():
  global n
  n = 0
  stop()
  T(5,  20)
  Y(21, 20)
  T(38, 20)
  H(52, 20)
  O(70, 20)
  N(85, 20)

  CallIn(simtime.onesec * TythonTime, RANDOM)

def RANDOM():
  stop()
  for mote in motes:
    mote.turnOff()
    motemover.randomWalk(mote, step)
    
  CallIn(simtime.onesec * RandomTime, TYTHON)

RandomTime = 30
TythonTime = 60

argv = simcore.sim.argv
for i in range(len(argv)):
  if (argv[i] == "-randomtime"):
    i += 1
    RandomTime = int(argv[i])

  if (argv[i] == "-tythontime"):
    i += 1
    TythonTime = int(argv[i])


try:
  sim.exec("apps/Blink/build/pc/main.exe", 56, "-l=1.0 -s=0")
except:
  print "\n\nError running apps/Blink/build/pc/main.exe, most likely"
  print "because you're not in the right directory or it's not built yet."
  sim.exit()
  
# No need for the radio model plugin to do all that work, nor do we
# need any events other than interrupts and leds
simcore.radio.disable()
simcore.comm.setEventMask(InterruptEvent.AM_TYPE | LedEvent.AM_TYPE)

for mote in motes:
  mote.turnOff()
TYTHON()

sim.resume()
