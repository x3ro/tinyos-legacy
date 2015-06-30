#!/usr/bin/env python

class mote:
    keys = ("ID", "X", "Y", "pot", "edge", "MoteType", "Name")
    
    def __init__(self, ID, X, Y, edge, MoteType = 1, pot = 9, Name = ""):
        self.ID = ID
        self.X = X
        self.Y = Y
        self.edge = edge
        self.pot = pot
	self.MoteType = MoteType
	self.Name = Name

    def __str__(self):
        return "mote " + " ".join(["%s=%s" % (key, getattr(self, key))
                                  for key in self.keys])

def makeField(fieldX, fieldY, moteSpacingX, moteSpacingY,
              moteNumX, moteNumY, identStart = 0):
    return [mote(identStart + nx + (ny * moteNumX),
                 fieldX + (nx * moteSpacingX),
                 fieldY + (ny * moteSpacingY),
                 (nx == 0) or (nx == (moteNumX - 1)) or
                 (ny == 0) or (ny == (moteNumY - 1))) 
             for ny in range(moteNumY)
            for nx in range(moteNumX)]


if __name__ == "__main__":
    print "motefield ID=0 BackgroundFile=script.jpg Screen1X= Screen1Y= World1X= World1Y= Screen2X= Screen2Y= World2X= World2Y= MoteSize= IconSize="

    width  = 50.0
    height = 30.0
    nodesAcross = 5
    nodesDown   = 3
    hspacing = width / (nodesAcross - 1)
    vspacing = height / (nodesDown - 1)

    for m in makeField(0, 0, hspacing, vspacing, nodesAcross, nodesDown):
        print m
