package net.tinyos.tosser;

import java.util.*;

public class SimulatorEvent {
    protected Vector wires;
    protected long time;
    protected String pinName;

    public SimulatorEvent(long time, String pinName, Workspace ws) {
        this.time = time;
        wires = ws.getWiresOnPinoutByName(pinName);
        this.pinName = pinName;
    }

    public long getTime() {
        return time;
    }

    public Vector getWires() {
        return wires;
    }

    public String getPinName() {
        return pinName;
    }
}
