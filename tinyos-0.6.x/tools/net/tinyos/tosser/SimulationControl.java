package net.tinyos.tosser;

import java.awt.*;
import javax.swing.*;


public class SimulationControl extends JPanel {
    private ProgressBar progress;
    private RateBar rate;
    private RateValues values;
    private JTextArea messageArea;
    private JScrollPane scrollPane;

    public SimulationControl() {
        super();
        rate = new RateBar();

        setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

        add(rate);

        messageArea = new JTextArea();
        scrollPane = new JScrollPane(messageArea);
        add(scrollPane);
    }

    public void eventPause() throws TimeShiftException {
        int ticksPerSec = rate.getRate();
        int eventTicks = rate.getExecTicks();

        int msecPerTick = 1000 / ticksPerSec;
        int msecPerEvent = msecPerTick * eventTicks;

        try {
            //System.out.println("Sleeping for " + msecPerEvent + " msec");
            Thread.sleep(msecPerEvent);
        }
        catch (InterruptedException exception) {
            System.err.println("Pause woken from sleep.");
        }
    }

    public void idlePause() throws TimeShiftException {
        int ticksPerSec = rate.getRate();
        int idleTicks = rate.getIdleTicks();

        int msecPerTick = 1000 / ticksPerSec;
        int msecPerIdle = msecPerTick * idleTicks;

        try {
            //System.out.println("Sleeping for " + msecPerIdle + " msec");
            Thread.sleep(msecPerIdle);
        }
        catch (InterruptedException exception) {
            System.err.println("Pause woken from sleep.");
        }
    }

    public void addMessage(String text) {
        messageArea.append(text);
        JScrollBar scrollBar = scrollPane.getVerticalScrollBar();
        scrollBar.setValue(scrollBar.getMaximum());
    }
        
    public static void main(String[] args) {
        SimulationControl control = new SimulationControl();
        JFrame frame = new JFrame("Simulation Control Test");
        frame.getContentPane().add(control);
        frame.pack();
        frame.setVisible(true);

        boolean event = true;
        for (int i = 0; i < 100; i++) {
            int val = (int)(Math.random() * 2.0);
            event = (event || (val > 0));
            if (event) {
                try {
                    control.eventPause();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                System.out.println("Event.\n");
                event = false;
            }
            else {
                try {
                    control.idlePause();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                System.out.println("Idle.\n");
                event = true;
            }
        }
    }
}
