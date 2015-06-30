#
# Dummy script that registers itself to get events and prints them out
#

from simcore import *
from net.tinyos.sim.event import SimulationPausedEvent
from java.util import Random

class MoteMover:
  
  rate = 4000000; # once per second
  handlers = {};

  def stop(self, moteID):
    if (self.handlers.has_key(moteID) == False):
      raise IndexError, "Mote ID " + moteID + " not moving"

  def random_walk(self, moteID, distance):
    print "random_walk(%d, %d)" % (moteID, distance);
    
    if (self.handlers.has_key(moteID)):
      raise IndexError, "Mote ID " + moteID + " already on the move"

    pauseID = comm.getPauseID();
    r = Random();
    
    def random_walk_pause(pauseEvent):
      if (pauseEvent.get_id() == pauseID):
        x = r.nextDouble() * distance * 2.0 - distance;
        y = r.nextDouble() * distance * 2.0 - distance;
        motes[moteID].move(x, y)
        # print "random_walk: move mote %d by (%d, %d)" % (moteID, x, y);
        comm.pauseInFuture(pauseEvent.getTime() + self.rate, pauseID)
          
    eventID = interp.addEventHandler(random_walk_pause, SimulationPausedEvent)
    comm.pauseInFuture(0, pauseID) # First step is now
    self.handlers[moteID] = (eventID, 'random_walk', pauseID)
