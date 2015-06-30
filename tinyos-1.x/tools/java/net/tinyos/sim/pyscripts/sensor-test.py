# This script is in the public domain and has no copyright
#
# This is a simple example script that demonstrates the use of
# SimObjects that are not Motes to represent a sensor value. In this
# case, it models two "lightbulbs" that move to and from a pair of
# motes.
#

from simcore import *
from simutil import *

from net.tinyos.sim import *

class MovingLight:
    def __init__(self, id, x, y, nsteps):
        self.obj  = sim.newSimObject(3, x, y)
        self.attr = SensorAttribute("light", 7<<7)
        self.obj.addAttribute("light", self.attr)
        self.obj.addAttributeChangedEvent(self.attr);

        d = self.obj.getDistance(20, 55)
        step = d / nsteps

        def moveTowardsMotes(obj):
            objmover.moveTo(obj, id, step, 20, 55, moveBackHome)

        def moveBackHome(obj):
            objmover.moveTo(obj, id, step, x, y, moveTowardsMotes)

        moveTowardsMotes(self.obj)


sim.exec("apps/SenseToLeds/build/pc/main.exe", 2, "-b=1 -l=1.0")

myModel = LinearSensorModel(10.0, 100.0)
sensor.addModel("mymodel", myModel)
sensor.addField("light", 1, "mymodel")

motes[0].moveTo(20, 50)
motes[1].moveTo(20, 60)

lights = {}
lights[0] = MovingLight(0, 80, 70, 10)
lights[1] = MovingLight(1, 80, 30, 20)

sim.resume()

