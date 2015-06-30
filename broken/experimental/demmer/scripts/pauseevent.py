#
# Dummy script that registers itself to get events and prints them out
#

from net.tinyos.sim.event import *
from java.util import Random

r = Random()
pauseID = 1

def pause_handle(event):
  if (SimulationPausedEvent.isInstance(event)):
    global pauseID
    if event.get_id() == pauseID:
      motes[0].move(r.nextDouble(), r.nextDouble())
      comm.pauseInFuture(event.getTime() + 4000000, pauseID)
      radio.updateModel()
      radio.publishModel()
      print motes[0]

interp.addEventHandler(pause_handle)
comm.pauseInFuture(4000000, pauseID)
print "ID:",pauseID
sim.resume()
