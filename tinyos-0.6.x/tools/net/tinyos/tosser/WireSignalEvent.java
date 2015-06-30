package net.tinyos.tosser;

import java.util.*;

public class WireSignalEvent extends SimulatorEvent {
    private static final long interval = 250;
    private Wire w;
    private boolean switchOn = true;
    
    public WireSignalEvent(Wire w, long time, boolean switchOn) {
        super(time);

        this.w = w;
        this.switchOn = switchOn;
    }

    public WireSignalEvent(Wire w, long time) {
        super(time);

        this.w = w;
    }

    public WireSignalEvent(Wire w) {
        super(System.currentTimeMillis() + interval);

        this.w = w;
    }

    public Collection doEvent(SortedSet pQueue, long currentTime) {
        if (switchOn) {
            w.signalOn();
            Vector v = new Vector(1);
            v.add(new WireSignalEvent(w, time + interval, false));
            return v;
        } else {
            w.signalOff();
            return new Vector(0);
        }
    }

    public String toString() {
        return "<" + time + ", " + w + ">";
    }
}
