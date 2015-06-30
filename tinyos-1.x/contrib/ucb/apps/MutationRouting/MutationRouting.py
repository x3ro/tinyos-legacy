from simcore import *
#sim.connect()
if len(motes) == 102:
    num = "10"
elif len(motes) == 627:
    num = "25"
elif len(motes) == 963:
    num = "31"
elif len(motes) == 1602:
    num = "40"

execfile("location"+num+".py")
execfile("MutationRoutingStart.py")
execfile("MutationRoutingLeader.py")
execfile("Pursuer1Path.py")
execfile("EvaderPath.py")
sim.resume()
