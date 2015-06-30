# This script is in the public domain and has no copyright
#
# CallAt/CallIn are simple utility classes that call a specified
# function at a given point in the future.
#

import simcore
import net.tinyos.sim.event

class CallAt:
    def __init__(self, when, callback, args = None):
        interruptID = simcore.interp.getInterruptID()

        def mycallback(interruptEvent):
            if (interruptEvent.get_id() != interruptID):
                return
            simcore.interp.removeEventHandler(self.eventID);
            if args != None:
                callback(args);
            else:
                callback();

        evclass = net.tinyos.sim.event.InterruptEvent
        self.eventID = simcore.interp.addEventHandler(mycallback, evclass);
        simcore.interp.interruptInFuture(when, interruptID)

    def cancel(self):
        simcore.interp.removeEventHandler(self.eventID)

class CallIn(CallAt):
    def __init__(self, delay, callback, args = None):
        when = simcore.sim.getTossimTime() + delay;
        CallAt.__init__(self, when, callback, args);



