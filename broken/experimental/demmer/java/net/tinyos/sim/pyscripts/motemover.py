#
# MoteMover is a utility class that handles various movement patterns
# for motes. 
#

import simcore
import simutil
import simtime

from net.tinyos.sim.event import SimulationPausedEvent
from java.util import Random

# there should be only a single instance
motemover = None;

class MoteMover:
  def __init__(self):
    global motemover
    if (motemover != None):
      raise "Cannot instantiate MoteMover more than once"
    
  handlers = {}
  rate = simtime.onesec

  #
  # Set the step rate in simulator time units, i.e. 4MHz
  #
  def setDefaultRate(self, rate):
    self.rate = rate

  #
  # Return a boolean indication whether or not this mote is moving
  #
  def isMoving(self, mote):
    return self.handlers.has_key(mote.getID());

  #
  # Move the mote to the given x,y position, moving a distance of
  # 'step' each time. Calls the arrivedCallback when it gets there.
  #
  def moveTo(self, mote, step, x, y, arrivedCallback = None, rate = -1):
    moteID = mote.getID();
    if rate == -1:
      rate = int(self.rate)
    
    if (self.handlers.has_key(moteID)):
      raise IndexError("Mote ID %d already on the move" % moteID)

    dx = x - mote.getXCoord();
    dy = y - mote.getYCoord();
    distance = mote.getDistance(x, y);
    nsteps = distance / step;
    xstep = dx / nsteps;
    ystep = dy / nsteps;

    def callback(pauseEvent):
      distance = mote.getDistance(x, y);
      if (distance < step):
        mote.moveTo(x, y);
        self.stop(mote); # clear handlers, cancel event, etc
        if (arrivedCallback != None):
          arrivedCallback(mote)
      else:
        mote.move(xstep, ystep);

    periodic = simutil.Periodic(rate, callback);
    self.handlers[moteID] = (periodic, 'move_to');

  #
  # Move the given mote in a random walk pattern, moving a distance of
  # 'step' units on each time interval.
  #
  def randomWalk(self, mote, step, rate=-1):
    moteID = mote.getID();
    
    if rate == -1:
      rate = self.rate
      
    if (self.handlers.has_key(moteID)):
      raise IndexError("Mote ID %d already on the move" % moteID)

    r = Random();
    
    def callback(pauseEvent):
      x = r.nextDouble() * step * 2.0 - step;
      y = r.nextDouble() * step * 2.0 - step;
      simcore.motes[moteID].move(x, y)
      # print "random_walk: move mote %d by (%d, %d)" % (moteID, x, y);
      
    periodic = simutil.Periodic(rate, callback);
    self.handlers[moteID] = (periodic, 'random_walk')

  #
  # Stop the given mote from moving.
  #
  def stop(self, mote):
    moteID = mote.getID()
    if (self.handlers.has_key(moteID) == False):
      raise IndexError, "Mote ID % not moving" % moteID

    (periodic, what) = self.handlers.get(moteID);
    periodic.stop();
    del self.handlers[moteID]

#
# Create the global instance once
#
motemover = MoteMover()
