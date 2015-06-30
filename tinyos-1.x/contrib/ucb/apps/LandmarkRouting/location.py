from simcore import *
import math
if len(motes) == 102:
    separationWidth = 10.9
    separationHeight = 10.9
elif len(motes) == 227:
    separationWidth = 7
    separationHeight = 7
elif len(motes) == 402:
    separationWidth = 5.15
    separationHeight = 5.15
elif len(motes) == 902:
    separationWidth = 3.375
    separationHeight = 3.375
elif len(motes) == 1602:
    separationWidth = 2.5
    separationHeight = 2.5
else:
    separationWidth = 1
    separationHeight = 1

width = 1
height = 1
for i in motes:
    if i.getID() == 0 or i.getID() == 1:
        i.setCoord(sim.worldHeight, sim.worldWidth)
    else:
        if width > sim.worldWidth:
            width = 1
            height += separationHeight
        i.setCoord(width, height)
        width += separationWidth
