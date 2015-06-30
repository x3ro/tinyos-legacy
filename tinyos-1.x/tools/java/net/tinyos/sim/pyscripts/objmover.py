# This script is in the public domain and has no copyright
#
# ObjMover is a utility class that handles various movement patterns
# for SimObjects
#

import simcore
import simutil
import simtime
import math

from net.tinyos.sim.event import InterruptEvent

# there should be only a single instance
objmover = None;

class ObjMover:
  def __init__(self):
    global objmover
    if (objmover != None):
      raise "Cannot instantiate Objmover more than once"

  handlers = {}
  rate = simtime.onesec

  #
  # Set the step rate in simulator time units, i.e. 4MHz
  #
  def setDefaultRate(self, rate):
    self.rate = rate

  #
  # Return a boolean indication whether or not the object is moving
  #
  def isMoving(self, id):
    return self.handlers.has_key(id)

  #
  # Move the object to the given x,y position, moving a distance of
  # 'step' each time. Calls the arrivedCallback when it gets there.
  #
  def moveTo(self, object, id, step, x, y, arrivedCallback = None, rate = -1):
    if rate == -1:
      rate = int(self.rate)
    
    if (self.handlers.has_key(id)):
      raise IndexError("Object ID %d already on the move" % id)

    dx = x - object.getXCoord();
    dy = y - object.getYCoord();
    distance = object.getDistance(x, y);
    nsteps = distance / step;
    xstep = dx / nsteps;
    ystep = dy / nsteps;

    def callback(pauseEvent):
      distance = object.getDistance(x, y);
      if (distance < step):
        object.moveTo(x, y);

        # call stop to clear handlers, cancel event, etc. note that we
        # need to explicitly call the ObjMover version of this method
        # to avoid calling that of any derived classes
        ObjMover.stop(self, id);
        
        if (arrivedCallback != None):
          arrivedCallback(object)
      else:
        object.move(xstep, ystep);

    periodic = simutil.Periodic(rate, callback);
    self.handlers[id] = (periodic, 'move_to');

  #
  # Move the given object in a random walk pattern, moving a distance of
  # 'step' units on each time interval.
  #
  def randomWalk(self, object, id, step, rate=-1):
    if rate == -1:
      rate = self.rate
      
    if (self.handlers.has_key(id)):
      raise IndexError("Object ID %d already on the move" % id)

    def callback(pauseEvent):
      x = simcore.random.nextDouble() * step * 2.0 - step;
      y = simcore.random.nextDouble() * step * 2.0 - step;
      object.move(x, y)
      
    periodic = simutil.Periodic(rate, callback);
    self.handlers[id] = (periodic, 'random_walk')

  #
  # Move the given object in a constrained random walk pattern, moving a
  # distance of 'step' units on each time interval, and turning based
  # on a random angle from -turnRange...turnRange.
  #
  def randomTrajectory(self, object, id, step, turnRange, rate=-1):
    if rate == -1:
      rate = self.rate
      
    if (self.handlers.has_key(id)):
      raise IndexError("Object ID %d already on the move" % id)

    def callback(pauseEvent):
      angle = self.handlers[id][2]
      dAngle = simcore.random.nextDouble() * turnRange * 2.0 - turnRange
      newAngle = (angle + dAngle + 360) % 360

      # check if we're at the edge of the world, if so, pick a random
      # angle to get off it
      x = object.getXCoord()
      y = object.getYCoord()
      if (x == 0 or x == simcore.sim.getWorldWidth() or
          y == 0 or y == simcore.sim.getWorldHeight()):
        newAngle = simcore.random.nextDouble() * 360

      dx = math.cos((newAngle / 360) * (2 * math.pi)) * step
      dy = math.sin((newAngle / 360) * (2 * math.pi)) * step
      object.move(dx, dy)

      self.handlers[id] = (periodic, 'randomTrajectory', newAngle)

    periodic = simutil.Periodic(rate, callback)
    self.handlers[id] = (periodic, 'randomTrajectory', 0)
    
  #
  # Stop the given object from moving.
  #
  def stop(self, id):
    if (self.handlers.has_key(id) == False):
      raise IndexError, "Object ID %d not moving" % id

    (periodic, what) = self.handlers.get(id);
    periodic.stop();
    del self.handlers[id]

#
# Create the global instance once
#
objmover = ObjMover()
