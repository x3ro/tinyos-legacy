#
# Dummy script that registers itself to get events and prints them out
#

from net.tinyos.sim.event import *
from java.util import Random

def random_walk(moteID, rate, distance):
  global functions
  r = Random();
  pauseID = comm.getPauseID();
  functions[pauseID] = 1  
  def pause_handle(event):
    if (SimulationPausedEvent.isInstance(event)):
      if event.get_id() == pauseID:
        x = r.nextDouble() * distance * 2.0 - distance;
        y = r.nextDouble() * distance * 2.0 - distance;
        motes[moteID].move(x, y)
        if (functions[pauseID] == 1):
          comm.pauseInFuture(event.getTime() + rate, pauseID)
        radio.updateModel()
        radio.publishModel()
        print motes[moteID]
  interp.addEventHandler(pause_handle)
  comm.pauseInFuture(0, pauseID) # First step is now
  print "Registered function:", pauseID
  return pauseID



class RandomWalk:
  running = 0
  id = 0
  rate = 0
  distance = 0
  pauseID = comm.getPauseID()
  handler = 0
  rgen = Random()
  
  def __init__(self, moteID, rate, distance):
    self.id = moteID
    self.rate = rate
    self.distance = distance


  def start(self, time=0):
    if (self.running == 0):
      self.pauseID = comm.getPauseID()

      def pause_handle(event):
        if (SimulationPausedEvent.isInstance(event)):
          if event.get_id() == self.pauseID:
            x = self.rgen.nextDouble() * self.distance * 2.0 - self.distance;
            y = self.rgen.nextDouble() * self.distance * 2.0 - self.distance;
            motes[self.id].move(x, y)
            if (self.running):
              comm.pauseInFuture(event.getTime() + self.rate, self.pauseID)
            radio.updateModel()

      self.running = 1
      self.handler = interp.addEventHandler(pause_handle)
      comm.pauseInFuture(time, self.pauseID) # First step is now
      print "Registered function:", self.pauseID
    else:
      print "Random walk is already started."

  def stop(self):
    interp.removeEventHandler(self.handler)
    self.running = 0
    
