package net.tinyos.tosser;

import java.util.*;
import java.awt.*;

public class EventQueueThread extends Thread {
    private LinkedList eQueue;
    private Component comp;
    private SimulationControl simCntl;

    public EventQueueThread(LinkedList eQueue, SimulationControl simCntl, 
                            Component comp) {
        this.eQueue = eQueue;
        this.simCntl = simCntl;
        this.comp = comp;
    }

    public void run() {
        long currentTime = 0;
        while (true) synchronized (eQueue) {
            while (eQueue.isEmpty()) {
                try {
                    eQueue.wait();
                } catch (InterruptedException e) {}
            }

            Iterator iter = eQueue.iterator();
            while (iter.hasNext()) {
                SimulatorEvent simuEvent = (SimulatorEvent)iter.next();

                if (simuEvent.getTime() > currentTime) {
                    try {
                        simCntl.idlePause();
                    } catch (TimeShiftException tse) {}
                    currentTime = simuEvent.getTime();
                    Vector wires = simuEvent.getWires();
                }

                Iterator wIter;

                wIter = simuEvent.getWires().iterator();
                while (wIter.hasNext()) {
                    Wire w = (Wire)wIter.next();
                    w.signalOn();
                }
                comp.repaint();
                simCntl.addMessage("Signaling " + simuEvent.getPinName() + 
                                   "... ");

                try {
                    simCntl.eventPause();
                } catch (TimeShiftException tse) {}

                wIter = simuEvent.getWires().iterator();
                while (wIter.hasNext()) {
                    Wire w = (Wire)wIter.next();
                    w.signalOff();
                }
                comp.repaint();
                simCntl.addMessage("done\n");

                iter.remove();
            }

            yield();
        }
    }
}
