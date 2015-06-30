# This script is in the public domain and has no copyright
#
# This is a simple script that tests objmover.
#

from simcore import *
from simutil import *

from net.tinyos.sim import *

class MovingObj:
    def __init__(self, id, x, y, nsteps):
        self.obj  = sim.newSimObject(3, x, y)

        d = self.obj.getDistance(20, 55)
        step = d / nsteps

        def moveAway(obj):
            objmover.moveTo(obj, id, step, 20, 55, moveBackHome)

        def moveBackHome(obj):
            objmover.moveTo(obj, id, step, x, y, moveTowardsMotes)

        moveAway(self.obj)

sim.exec("apps/SenseToLeds/build/pc/main.exe", 1, "-b=1 -l=1.0")
motes[0].moveTo(20, 50)
comm.setADCValue(0, 0, 1, 0);

objs = {}
objs[0] = MovingObj(0, 80, 70, 10)
objs[1] = MovingObj(1, 80, 30, 20)

sim.resume()

