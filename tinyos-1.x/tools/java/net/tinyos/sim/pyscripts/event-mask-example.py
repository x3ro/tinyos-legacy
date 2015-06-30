# This script is in the public domain and has no copyright
#
# This is a simple example script to demonstrate the use of event
# masks to limit the communication between TOSSIM and Tython to
# improve the execution time of the tools.
#

import time
from simcore import *
from simutil import *
from net.tinyos.sim.msg import *

def handler(event):
    print "got event", event

interp.addEventHandler(handler)

sim.exec("apps/SenseToRfm/build/pc/main.exe", 2, "-b=1")

print "Running for two seconds with all events except DebugMsgEvent"
sim.resume()
comm.setEventMask(~ DebugMsgEvent.AM_TYPE)
comm.waitFor(2 * simtime.onesec)

print "Masking all events except InterruptEvent"
comm.setEventMask(InterruptEvent.AM_TYPE)
comm.waitFor(2 * simtime.onesec)

print "Masking all events except InterruptEvent and RadioMsgSentEvent"
comm.setEventMask(InterruptEvent.AM_TYPE | RadioMsgSentEvent.AM_TYPE)
comm.waitFor(2 * simtime.onesec)

print "Unmasking all events for a two seconds (of real time)"
comm.setEventMask(~0)
time.sleep(2)

print "Done."
sim.exit()
