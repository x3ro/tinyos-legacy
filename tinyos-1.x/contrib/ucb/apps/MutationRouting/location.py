from simcore import *
import math
separationWidth = 10.9
separationHeight = 10.9
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
