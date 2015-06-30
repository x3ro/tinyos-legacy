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

import java.util.*;
import java.text.*;
import javax.swing.*;
import java.awt.*;


class MercuryMotePanel extends JPanel
{
    // =========================== Data Members ================================
    private int moteID = 0;

    // for stats
    int nbrRecvMsgs = 0;
    int nbrLostMsgs = 0;
    int prevSqnNbr = 0;

    private static final int MAX_SQNNBR = ((int)Math.pow(2,16)-1);
    private static final int REBOOT_TH = 100;
    //private static final int WRAPAROUND_TH = Math.pow(2,15);


    // GUI stuff
    private JPanel statsPanel = new JPanel();
    private JLabel nbrRecvMsgsJLabel = new JLabel("Nbr Recv Msgs: ");
    private JTextField nbrRecvMsgsTextField = new JTextField(5);

    private JLabel percRecvMsgsJLabel = new JLabel("Perc Recv Msgs: ");
    private JTextField percRecvMsgsTextField = new JTextField(5);

    private Map<Integer, GraphPanel> graphPanels = new HashMap<Integer,GraphPanel>();


    // =========================== Methods ================================
    MercuryMotePanel(int moteID)
    {
        this.moteID = moteID;

        // GUI stuff
        this.setBorder(BorderFactory.createTitledBorder("NodeID= " + moteID));
        this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

        createStatsPanel();
        this.add(statsPanel);
    }

    private void createStatsPanel()
    {
        Font font1 = new Font("Helvetica", Font.BOLD, 18);

        nbrRecvMsgsJLabel.setFont(font1);
        percRecvMsgsJLabel.setFont(font1);


        // the JTextFields
        Font font2 = new Font("Helvetica", Font.BOLD, 18);

        nbrRecvMsgsTextField.setFont(font2);
        percRecvMsgsTextField.setFont(font2);

        nbrRecvMsgsTextField.setForeground(Color.red);
        percRecvMsgsTextField.setForeground(Color.red);

        nbrRecvMsgsTextField.setEditable(false);
        percRecvMsgsTextField.setEditable(false);


        // layout
        statsPanel.setLayout(new GridBagLayout());
        GridBagConstraints c = new GridBagConstraints();
        //c.fill = GridBagConstraints.HORIZONTAL;
        c.anchor = GridBagConstraints.EAST;
        c.insets = new Insets(1,1,1,1);  // padding
        //c.weightx = 1.0;

        // NbrRevMsgs
        c.gridx = 0; c.gridy = 0;
        statsPanel.add(nbrRecvMsgsJLabel, c);

        c.gridx = 1;  c.gridy = 0;
        statsPanel.add(nbrRecvMsgsTextField, c);

        // PercRecvMsgs
        c.gridx = 0;  c.gridy = 1;
        statsPanel.add(percRecvMsgsJLabel, c);

        c.gridx = 1;  c.gridy = 1;
        statsPanel.add(percRecvMsgsTextField, c);
    }

    public int getMoteID()  {return moteID;}

    private int percRecvMsgs()
    {
        if (nbrRecvMsgs + nbrLostMsgs == 0)
            return 100;
        else
            return Math.round((float)100*(float)nbrRecvMsgs / (float)(nbrRecvMsgs+nbrLostMsgs));
    }


    public void addSamples(int sqnNbr, double firstMCSTimeSec, int[] samples)
    {
        // (1) - Update stats
        // Check for: corrupt packet
        if (sqnNbr < 0 || sqnNbr > MAX_SQNNBR) {
            return;     // corrupt packet
        }
        // Check for: startup and old msgs left in the SerialForwarder queue
        else if (nbrRecvMsgs < 30) {
            nbrRecvMsgs++;
            prevSqnNbr = sqnNbr;
        }
        // Check for: wraparound
        else if (sqnNbr < prevSqnNbr && (MAX_SQNNBR+sqnNbr) - prevSqnNbr < REBOOT_TH) {  // wraparound
            nbrRecvMsgs++;
            nbrLostMsgs += (MAX_SQNNBR+sqnNbr) - prevSqnNbr - 1;
            prevSqnNbr = sqnNbr;
        }
        // Check for: reboot
        else if (Math.abs(sqnNbr - prevSqnNbr) > REBOOT_TH) {
            // don't penalize for reboots
            nbrRecvMsgs++;
            prevSqnNbr = sqnNbr;
        }
        // Check for: delayed packet
        else if (sqnNbr < prevSqnNbr) {
            // just drop it
            return;
        }
        // Must be the "normal"/common case
        else {
            nbrRecvMsgs++;
            nbrLostMsgs += sqnNbr - prevSqnNbr - 1;
            prevSqnNbr = sqnNbr;
        }


        // (2) - Add the samples
        for (int i = 0; i < samples.length; ++i) {
            int chanID = i % MercurySampling.MERCURY_NBR_CHANS;
            double deltaTimeSec = (double)(i/MercurySampling.MERCURY_NBR_CHANS) /
                                  (double)(MercurySampling.MERCURY_SAMPLING_RATE / MercurySampling.MERCURY_NBR_CHANS);
            double currMCSTimeSec = firstMCSTimeSec + deltaTimeSec;

            getGraphPanel(chanID).addData(currMCSTimeSec, (samples[i] & 0x0fff));
        }

        // (3) - Update the GUI
        nbrRecvMsgsTextField.setText(nbrRecvMsgs + "");
        percRecvMsgsTextField.setText(percRecvMsgs() + "%");

    }

    private String getChannelStr(int channelID)
    {
        // NOTICE: This maps to the ordering of the channels in MercurySampling.h!
        switch(channelID) {
            case 0:  return "Acc X";
            case 1:  return "Acc Y";
            case 2:  return "Acc Z ";
            case 3:  return "Gyro X";
            case 4:  return "Gyro Y";
            case 5:  return "Gyro Z";
            default: return "Unknown Channel";
        }
    }

    private GraphPanel getGraphPanel(int channelID)
    {
        GraphPanel gp = graphPanels.get(channelID);
        if (gp == null) {
            // construct the GraphPanel
            gp = new GraphPanel(getChannelStr(channelID), "Elapsed time (sec)", "ADC value", new double[]{0}, new double[]{0});
            gp.setPreferredSize(new Dimension(600, 150));
            graphPanels.put(channelID, gp);
            this.add(gp);
        }
        return gp;
    }
}
