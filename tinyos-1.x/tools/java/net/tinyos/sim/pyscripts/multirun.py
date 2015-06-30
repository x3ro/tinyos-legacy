# This script is in the public domain and has no copyright
#
# This script is just a syntax example for scripting multiple runs of
# a simulation. It doesn't do anything real.

from simcore import *
import simtime

def run(duration):
    try:
        sim.exec("apps/CntToRfm/build/pc/main.exe", 2, "-b=0")
    except:
        print "\n\nError running apps/CntToRfm/build/pc/main.exe, most likely"
        print "because you're not in the right directory or it's not built yet."
        sim.exit()

    comm.waitFor(duration * simtime.onesec)
    sim.pause()
    count0 = motes[0].getInt("Counter$state")
    count1 = motes[1].getInt("Counter$state")
    print "\n\n Count Run Complete"
    print "mote 0 count %d" % count0
    print "mote 1 count %d" % count1
    print "\n"
    
    print "Resetting Simulation..."
    sim.stop()
    sim.reset()

run(10)
run(20)
run(30)
sim.exit()
