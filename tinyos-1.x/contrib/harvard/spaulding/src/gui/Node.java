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
import java.io.Serializable;


/**
 * <p>NodeListener - This interface is used as a callback that the state of the node
 * has changed.  In particular, node views (i.e. various node Panels) should implement
 * this interface.</p>
 *
 * @author Konrad Lorincz
 * @version 1.0
 */
interface NodeListener
{
    public void newSamplingMsg(SamplingMsg samplingMsg);
    public void newReplyMsg(ReplyMsg replyMsg);
}


class Node implements Serializable, Comparable<Node>
{
    // =========================== Data Members ================================
    private int nodeID = Integer.MAX_VALUE;
    transient private ReplyMsg lastReplyMsg = null;

    transient private List<NodeListener> nodeListeners = Collections.synchronizedList(new LinkedList<NodeListener>());


    // =========================== Methods ================================
    Node(int nodeID, ReplyMsg replyMsg)
    {
        assert (replyMsg != null && replyMsg.get_type() == DriverMsgs.REPLYMSG_TYPE_STATUS);
        assert (0 <= nodeID && nodeID < Math.pow(2,16)-1); // assume 16 bit addresses
        this.nodeID = nodeID;
        addReplyMsg(replyMsg);
    }

    public int getNodeID()  {return nodeID;}
    public int getDepth()   {return 1;}      // KLDEBUG - temporary

    public void addReplyMsg(ReplyMsg replyMsg)
    {
        assert (replyMsg != null);
        // KLDEBUG - think of a better way to handle this
        // Only accept ReplyStatusMsgs
        if (replyMsg.get_type() == DriverMsgs.REPLYMSG_TYPE_STATUS) {
            this.lastReplyMsg = replyMsg;

            // notify the NodeListeners
            for (NodeListener nl : this.nodeListeners)
                nl.newReplyMsg(replyMsg);
        }
    }
    public ReplyMsg getReplyMsg() {return lastReplyMsg;}
    public String getCurrState() {
        if ( (lastReplyMsg.get_data_status_systemStatus() &
              (1 << DriverMsgs.SYSTEM_STATUS_BIT_ISSAMPLING)) > 0 )
            return "SAMPLING";
        else
            return "READY_TO_SAMPLE";
    }
    public boolean getIsTimeSynchronized() {
        if ( (lastReplyMsg.get_data_status_systemStatus() &
              (1 << DriverMsgs.SYSTEM_STATUS_BIT_ISTIMESYNCED)) > 0 )
            return true;
        else
            return false;
    }

    public long getTailBlockID() {return lastReplyMsg.get_data_status_tailBlockID();}
    public long getHeadBlockID() {return lastReplyMsg.get_data_status_headBlockID();}
    public int getDataStoreQueueSize() {return lastReplyMsg.get_data_status_dataStoreQueueSize();}
    public long getLocalTime() {return lastReplyMsg.get_data_status_localTime();}
    public long getGlobalTime() {return lastReplyMsg.get_data_status_globalTime();}



    /**
     * The comparaTo method for the <code>Comparable</code> interface.
     * @param otherObj  the other signature to compare with.
     * @return  <code>-1 if (this.id < other.id), 0 if they are the same, and 1 if (this.id > other.id)</code>
     */
    public int compareTo(Node otherNode)
    {
        assert (otherNode != null);

        if (this.getNodeID() < otherNode.getNodeID())
            return -1;
        else if (this.getNodeID() == otherNode.getNodeID())
            return 0;
        else
            return 1;
    }

    public void newSamplingMsg(SamplingMsg samplingMsg)
    {
        // notify the NodeListeners
        for (NodeListener nl : this.nodeListeners)
            nl.newSamplingMsg(samplingMsg);
    }

    public void registerNodeListener(NodeListener nodeListener)
    {
        assert (nodeListener != null);
        nodeListeners.add(nodeListener);
    }

    public static String getChannelStr(int channelID)
    {
        // NOTICE: This maps to the ordering of the channels in MercurySampling.h!
        switch(channelID) {
            case 0:  return "Acc X";
            case 1:  return "Acc Y";
            case 2:  return "Acc Z";
            case 3:  return "Gyro X";
            case 4:  return "Gyro Y";
            case 5:  return "Gyro Z";
            case 6:  return "EMG";
            default: return "Unknown Channel";
        }
    }
}
