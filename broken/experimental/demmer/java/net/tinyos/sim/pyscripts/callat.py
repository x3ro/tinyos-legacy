#
# CallAt/CallIn are simple utility classes that call a specified
# function at a given point in the future.
#

import simcore
import net.tinyos.sim.event

class CallAt:
    def __init__(self, when, callback, args = None):
        pauseID = simcore.comm.getPauseID();

        def mycallback(pauseEvent):
            if (pauseEvent.get_id() != pauseID):
                return
            simcore.interp.removeEventHandler(self.eventID);
            if args != None:
                callback(args);
            else:
                callback();

        evclass = net.tinyos.sim.event.SimulationPausedEvent
        self.eventID = simcore.interp.addEventHandler(mycallback, evclass);
        simcore.comm.pauseInFuture(when, pauseID)

    def cancel(self):
        simcore.interp.removeEventHandler(self.eventID)

class CallIn(CallAt):
    def __init__(self, delay, callback, args = None):
        when = simcore.sim.getTossimTime() + delay;
        CallAt.__init__(self, when, callback, args);


