/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import javax.swing.*;
import java.awt.*;
import java.util.*;
import java.text.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class ReceiverGUI extends JPanel implements MessageListener
{
    // =========================== Data Members ================================
    private static final DecimalFormat dbFormat = new DecimalFormat("#.000");
    private static final int LOCAL_TIME_RATE_HZ = 32768;
    private Map<Integer, MercuryMotePanel> motePanels = new HashMap<Integer, MercuryMotePanel>();

    private static final boolean PRINT_SAMPLES_ENABLED = true;

    //private JTabbedPane motesTabbedPane = null;
    private long startTime = System.currentTimeMillis();

    // =========================== Methods ================================
    ReceiverGUI()
    {
        // GUI stuff
        this.setPreferredSize(new Dimension(600,600));
        //motesTabbedPane = new JTabbedPane(JTabbedPane.TOP, JTabbedPane.SCROLL_TAB_LAYOUT);
        this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
        //this.add(motesTabbedPane);

        // The MoteID stuff
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        mote.registerListener(new SamplingMsg(), this);

        // log Errors
        new ErrorToLedsReceiver();
    }

    synchronized public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof SamplingMsg) {

            SamplingMsg sMsg = (SamplingMsg) msg;

            int srcAddr = sMsg.get_srcAddr();
            int sqnNbr = sMsg.get_sqnNbr();
            long timeRaw = sMsg.get_timeStamp();
            double timeSec = (double)timeRaw/(double)LOCAL_TIME_RATE_HZ;

            int nbrSamples = sMsg.get_nbrSamples();
            int[] samples = new int[nbrSamples];
            // sanity check
            if (samples.length > sMsg.get_samples().length) {
                System.out.println("Dropping packet: packet must be corrupt.  samples.length=" +  samples.length +
                                   " > sMsg.get_samples().length=" + sMsg.get_samples().length);
                //assert (false);  // temporarily catch these
                return;
            }

            for (int i = 0; i < samples.length; ++i)
                samples[i] = sMsg.get_samples()[i];

            // Print to the standard out
            if (PRINT_SAMPLES_ENABLED) {
                System.out.print("\n\nsrcAddr= " + srcAddr +
                                 "  sqnNbr= " + sqnNbr +
                                 "  timeRaw= " + timeRaw +
                                 "  timeSec= " + dbFormat.format(timeSec) +
                                 "  nbrSamples= " + nbrSamples +
                                 "  chanMap= [");
                for (int i = 0; i < MercurySampling.MERCURY_NBR_CHANS; ++i) {
                    if (i != 0)
                        System.out.print(" ");
                    System.out.print((samples[i] >> 12));
                }
                System.out.print("], samples:");

                for (int i = 0; i < nbrSamples; ++i) {
                    if (i % MercurySampling.MERCURY_NBR_CHANS == 0) { // newline
                        double deltaTimeSec = (double)((int)i/(int)MercurySampling.MERCURY_NBR_CHANS) / (double)MercurySampling.MERCURY_SAMPLING_RATE;
                        double currMCSTimeSec = timeSec + deltaTimeSec;
                        System.out.print("\n    timeSec= " + dbFormat.format(currMCSTimeSec) + ", samples= ");
                    }
                    System.out.print(" " + (samples[i] & 0x0fff));
                }
            }

            // GUI stuff
            MercuryMotePanel motePanel = motePanels.get(srcAddr);
            if (motePanel == null) {
                motePanel = new MercuryMotePanel(srcAddr);
                motePanels.put(srcAddr, motePanel);
                //this.motesTabbedPane.add("MoteID= " + srcAddr, motePanel);
                this.add(motePanel);
                System.out.println("Mote added");
            }
            motePanel.addSamples(sqnNbr, timeSec, samples);
        }
    }


    /**
     * Create the GUI and show it.  For thread safety,
     * this method should be invoked from the
     * event-dispatching thread.
     */
    private static void createAndShowGUI() {
        //Make sure we have nice window decorations.
        JFrame.setDefaultLookAndFeelDecorated(true);

        //Create and set up the window.
        JFrame frame = new JFrame("Sampling Monitor - Harvard University");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        ReceiverGUI receiverGUI = new ReceiverGUI();
//        JScrollPane receiverGUIScrollPane = new JScrollPane(receiverGUI,
//                                                        JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
//                                                        JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
//        frame.setContentPane(receiverGUIScrollPane);
        frame.setContentPane(receiverGUI);

        //Display the window.
        frame.pack();
        frame.setVisible(true);
    }

    public static void main(String[] args) {
        //Schedule a job for the event-dispatching thread:
        //creating and showing this application's GUI.
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                createAndShowGUI();
            }
        });
    }
}
