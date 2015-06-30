
import simcore
from simutil import *

#
# Test script to exercise the mote movement.
#
def test():
  print "mote mover test running"
  x1 = 10; y1 = 10;
  x2 = 75; y2 = 35;
  
  def arrived(mote):
    print "arrived!"
    if (mote.getXCoord() == x2):
      motemover.moveTo(mote, 5, x1, y1, arrived)
    else:
      motemover.moveTo(mote, 5, x2, y2, arrived)

  motes[0].moveTo(x1, y1);
  motes[1].moveTo(x2, y2);

  motemover.moveTo(motes[0], 10, x2, y2, arrived);
  motemover.moveTo(motes[1], 10, x1, y1, arrived);
  motemover.randomWalk(motes[2], 5);

  print "Motemover.isMoving? %d" % motemover.isMoving(motes[0]);

  try:
    motemover.randomWalk(motes[0], 5);
  except:
    print "Caught error: ", sys.exc_info()[0]

test()
simcore.sim.resume();

