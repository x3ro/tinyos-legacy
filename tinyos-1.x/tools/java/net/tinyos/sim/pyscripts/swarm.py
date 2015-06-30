# This script is in the public domain and has no copyright
#
# Another silly example script

import simcore, simtime, simutil
from simcore import *
from net.tinyos.sim.event import *

step = 7
rate = 2 * simtime.onesec
threshold = 15
    
class Queen:
    def __init__(self, mote):
        self.mote = mote
        simutil.motemover.randomTrajectory(mote, step - 2, 20, rate)

class Bee:
    def __init__(self, mote, queen):
        self.mote = mote
        self.queen = queen
        simutil.Periodic(rate, self.move)

    def move(self, event):
        myX =    self.mote.getXCoord()
        myY =    self.mote.getYCoord()
        queenX = self.queen.getXCoord()
        queenY = self.queen.getYCoord()

        distance = self.mote.getDistance(self.queen)
        if (distance < threshold):
            # add a little jitter
            dx = (random.nextDouble() * 4) - 2
            dy = (random.nextDouble() * 4) - 2
        else:
            dx = ((queenX - myX) / distance) * step
            dy = ((queenY - myY) / distance) * step

        self.mote.move(dx, dy)

print "Swarm test running"

nmotes = 20
nqueens = 2
queens = {}
bees = {}

try:
  sim.exec("apps/Blink/build/pc/main.exe", 56, "-l=1.0 -s=0")
except:
  print "\n\nError running apps/Blink/build/pc/main.exe, most likely"
  print "because you're not in the right directory or it's not built yet."
  sim.exit()

# No need for the radio model plugin to do all that work, nor do we
# need any events other than interrupts and leds
simcore.radio.disable()
simcore.comm.setEventMask(InterruptEvent.AM_TYPE | LedEvent.AM_TYPE)

for i in range(nqueens):
    queens[i] = Queen(motes[i])

for i in range(nqueens - 1, len(motes)):
    bees[i] = Bee(motes[i], motes[i % nqueens])
