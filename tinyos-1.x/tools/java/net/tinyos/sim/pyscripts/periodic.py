# This script is in the public domain and has no copyright
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
        self.interruptID = simcore.interp.getInterruptID();
        self.stopped = 0;

        def mycallback(interruptEvent):
            if (interruptEvent.get_id() != self.interruptID):
                return
            self.callback(interruptEvent);
            if (self.stopped == 0):
                nextInterrupt = interruptEvent.getTime() + self.interval
                simcore.interp.interruptInFuture(nextInterrupt,
                                                 self.interruptID)

        evclass = net.tinyos.sim.event.InterruptEvent;
        self.eventID = simcore.interp.addEventHandler(mycallback, evclass);
        
        if call_immediate:
            simcore.interp.interruptInFuture(0, self.interruptID);
        else:
            simcore.interp.interruptInFuture(simcore.sim.getTossimTime()+
                                             self.interval, self.interruptID)

    def is_stopped(self):
        return self.stopped;
    
    def stop(self):
        self.stopped = 1;
        simcore.interp.removeEventHandler(self.eventID);
