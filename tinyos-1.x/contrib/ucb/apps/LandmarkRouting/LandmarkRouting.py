from simcore import *

execfile("location.py")
execfile("LandmarkRoutingStart.py")
execfile("LandmarkRoutingLandmark.py")
execfile("LandmarkRoutingLeader.py")
execfile("Pursuer1Path.py")
execfile("EvaderPath.py")
execfile("Watchdog.py")
execfile("RSSI.py")
sim.resume()
