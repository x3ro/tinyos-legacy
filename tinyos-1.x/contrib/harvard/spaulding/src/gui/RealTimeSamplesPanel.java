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

/**
 * @Konrad Lorincz
 * @version 1.0
 */
public class RealTimeSamplesPanel extends JPanel implements NodeListener
{
    // =========================== Data Members ================================
    private Node node = null;
    private Map<Integer, GraphPanel> graphPanels = new HashMap<Integer, GraphPanel>(); // <channelID, GraphPanel>


    // =========================== Methods ================================
    public RealTimeSamplesPanel(Node node)
    {
        assert (node != null);
        this.node = node;
        this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

        // Register as a NodeListeners
        node.registerNodeListener(this);
    }

    public void newSamplingMsg(SamplingMsg samplingMsg)
    {
        double timeSec = (double)samplingMsg.get_timeStamp()/(double)SpauldingApp.LOCAL_TIME_RATE_HZ;
        int samplingRate = samplingMsg.get_samplingRate();
        short[] channelIDs = samplingMsg.get_channelIDs();
        int nbrSamples = samplingMsg.get_nbrSamples();
        int[] samples = samplingMsg.get_samples();

        // Hack drop 1st samplingMsg because it's not initialized properly in RealTimeSamplesM.nc
        if (samplingMsg.get_sqnNbr() == 0)
            return;

        // (1) - Determine how many channels there are
        int nbrChannels = 0;
        for (short chanID: channelIDs) {
            if (chanID != MultiChanSampling.CHAN_INVALID)
                nbrChannels++;
        }

        // (2) - Get the samples
        for (int i = 0; i < nbrSamples; ++i) {
            int chanIndex = i % nbrChannels;
            //if (nbrChannels == 1)  // Quick HACK to identify EMG
            //    chanIndex = 6;
            double deltaTimeSec = (double)(i/nbrChannels) / (double)samplingRate;
            double currMCSTimeSec = timeSec + deltaTimeSec;
            getGraphPanel(chanIndex).addData(currMCSTimeSec, (samples[i] & 0x0fff));
        }

    }

    public void newReplyMsg(ReplyMsg replyMsg)
    {// we don't care about reply messages
    }

    private GraphPanel getGraphPanel(int channelID)
    {
        GraphPanel gp = graphPanels.get(channelID);
        if (gp == null) {
            // construct the GraphPanel
            gp = new GraphPanel(node.getChannelStr(channelID), "Elapsed time (sec)",
                                "ADC value", new double[] {0}, new double[] {0});
            gp.setMaxNbrValues(3500);
            gp.setPreferredSize(new Dimension(600, 150));
            graphPanels.put(channelID, gp);
            this.add(gp);
        }
        return gp;
    }
}
