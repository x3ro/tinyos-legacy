# This script is in the public domain and has no copyright
#
# MoteMover is a utility class that handles various movement patterns
# for motes. Much of the functionality has been folded into ObjMover,
# this just adds some interface sugar such that mote objects use
# their mote ID for movement patterns
#

from objmover import ObjMover

# there should be only a single instance
motemover = None;

class MoteMover(ObjMover):
  def __init__(self):
    global motemover
    if (motemover != None):
      raise "Cannot instantiate MoteMover more than once"
    
  #
  # Return a boolean indication whether or not this mote is moving
  #
  def isMoving(self, mote):
    return ObjMover.isMoving(self, mote.getID())

  #
  # Move the mote to the given x,y position, moving a distance of
  # 'step' each time. Calls the arrivedCallback when it gets there.
  #
  def moveTo(self, mote, step, x, y, arrivedCallback = None, rate = -1):
    return ObjMover.moveTo(self, mote, mote.getID(), step, x, y, arrivedCallback, rate)

  #
  # Move the given mote in a random walk pattern, moving a distance of
  # 'step' units on each time interval.
  #
  def randomWalk(self, mote, step, rate=-1):
    return ObjMover.randomWalk(self, mote, mote.getID(), step, rate)

  #
  # Move the given mote in a constrained random walk pattern, moving a
  # distance of 'step' units on each time interval, and turning based
  # on a random angle from -turnRange...turnRange.
  #
  def randomTrajectory(self, mote, step, turnRange, rate=-1):
    return ObjMover.randomTrajectory(self, mote, mote.getID(), step, turnRange, rate)
    
  #
  # Stop the given mote from moving.
  #
  def stop(self, mote):
    return ObjMover.stop(self, mote.getID())

#
# Create the global instance once
#
motemover = MoteMover()
