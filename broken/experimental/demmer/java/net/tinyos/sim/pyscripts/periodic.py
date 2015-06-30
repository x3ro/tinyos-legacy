#
# Periodic is a utility class to implement a repeated call to a 
# given callback function at a specified interval.
#

import simcore
import net.tinyos.sim.event

class Periodic:
    def __init__(self, interval, callback, args = None, call_immediate = 1):
        self.callback = callback;
        self.interval = int(interval)
        self.pauseID = simcore.comm.getPauseID();
        self.stopped = 0;

        def mycallback(pauseEvent):
            if (pauseEvent.get_id() != self.pauseID):
                return
            self.callback(pauseEvent);
            if (self.stopped == 0):
                simcore.comm.pauseInFuture(pauseEvent.getTime() + self.interval,
                                           self.pauseID)

        evclass = net.tinyos.sim.event.SimulationPausedEvent;
        self.eventID = simcore.interp.addEventHandler(mycallback, evclass);
        
        if call_immediate:
            simcore.comm.pauseInFuture(0, self.pauseID);
        else:
            simcore.comm.pauseInFuture(simcore.sim.getTossimTime()+self.interval,
                                       self.pauseID)

    def is_stopped(self):
        return self.stopped;
    
    def stop(self):
        self.stopped = 1;
        simcore.interp.removeEventHandler(self.eventID);
