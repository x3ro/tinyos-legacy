from simcore import *
execfile("location.py")
radio.setCurModel("disc10")
radio.setScalingFactor(.5)

pf = open('cellpacket','w')
space = ' '
end = ' 0.0 0.0\n'

for i in motes:
    for j in motes:
        s = str(i.getID()) + space + str(j.getID())
        if (i.getID() == 1 or i.getID() == 0):
            s += '1.0' + end
            pf.write(s)
        elif (j.getID == 1 or j.getID() == 0):
            s += '1.0' + end
            pf.write(s)
        else:
            s += str(radio.getLossRate(i.getID(),j.getID())) + end
            pf.write(s)
