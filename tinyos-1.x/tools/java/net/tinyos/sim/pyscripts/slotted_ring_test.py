# This script is in the public domain and has no copyright
#
# This script is really used just as an example, as the application
# that it really tests is not part of the tinyos distribution. Still,
# it demonstrates how to run a relatively complex mote movement
# pattern.

from simcore import *
from simutil import *

mobile_mote = -1

def init():
  print "Slotted Ring test starting up..."
  global mobile_mote

  motes[0].moveTo(50,40);
  motes[1].moveTo(43,43);
  motes[2].moveTo(40,50);
  motes[3].moveTo(43,57);
  motes[4].moveTo(50,60);
  motes[5].moveTo(57,57);
  motes[6].moveTo(60,50);
  motes[7].moveTo(57,43);
  
  motes[8].moveTo(80,50);
  mobile_mote = motes[8]

  for i in range(9):
    motes[i].turnOff();

  radio.setCurModel("disc10");
  radio.setScalingFactor(0.5);
  radio.updateModel();
  radio.setAutoPublish(True);
  radio.publishModel();

def updateVars(interval):
  print "Starting updateVars loop..."

  # Can't handle structs nicely yet, so hand-calculate the array
  # offset of the variable I want
  e = comm.resolveVariable(0, "SlottedRingM$neighbors_");
  mote0_missed_addr = e.get_addr() + 34;
  e = comm.resolveVariable(8, "SlottedRingM$neighbors_");
  mote5_missed_addr = e.get_addr() + 2;
  
  def update(event):
    global mobile_mote
    
    ring = motes[0].getInt("SlottedRingM$epoch_") - 1;
    e = comm.requestVariable(mote0_missed_addr, 2);
    missed = e.getShort_value(0);
    
    if (missed <= 0):
      motes[0].setLabel("ring: %d" % ring, -15, 15)
    else:
      motes[0].setLabel("ring: %d (missed: %d)" % (ring, missed), -15, 15)

    e = comm.requestVariable(mote5_missed_addr, 2);
    missed = e.getShort_value(0);
    if (missed <= 0):
      mobile_mote.setLabel("", 0, 0);
    else:
      mobile_mote.setLabel("(missed: %d)" % (missed), -15, 15);

  p = Periodic(interval, update);

def boot():
  print "Booting motes..."
  for i in range(8):
    print "boot mote %d at %d" % (i, sim.getTossimTime());
    motes[i].turnOn();
    comm.waitFor(2 * 4000000);

class MobileMoteMover:
  def __init__(self):
    global mobile_mote

    print "boot mote %d at %d" % (5, sim.getTossimTime());
    mobile_mote.turnOn();

    def moveToRing(mote):
      motemover.moveTo(mote, 5, 50, 50, arrivedInRing);

    def arrivedInRing(mote):
      CallIn(10 * 4000000, randomWalk, mote)

    def randomWalk(mote):
      motemover.randomWalk(mobile_mote, 5)
      CallIn(30 * 4000000, moveToEdge, mote);

    def moveToEdge(mote):
      motemover.stop(mote)
      motemover.moveTo(mote, 5, 90, 50, arrivedAtEdge);

    def arrivedAtEdge(mote):
      CallIn(15 * 4000000, moveToRing, mote);

    moveToRing(mobile_mote)

isSlottedRing = 0
try:
  sim.exec("apps/xxSlottedRing/build/pc/main.exe", 9)
  isSlottedRing = 1
except:
  print "WARNING: can't find slotted ring app, fallback to Blink"
  sim.exec("apps/Blink/build/pc/main.exe", 9)
  
init();
sim.resume();
if isSlottedRing:
  updateVars(2000000);
boot();
m = MobileMoteMover();
