/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

package net.tinyos.mccord;

import net.tinyos.util.*;
import net.tinyos.packet.*;
import net.tinyos.message.*;

import java.io.*;
import java.util.*;

public class McCORD implements MessageListener {
    public static final short TOS_UART_ADDR = 0x007e;
    public static final long METAMSG_TIMEOUT_MILLIS = 5000;
    public static final long DATAMSG_TIMEOUT_MILLIS = 1000;

    public MoteIF moteIf;
    public UARTMetaMsg metaMsg;
    public UARTDataMsg dataMsg;
    public boolean metaAcked = false;
    public FileInputStream fis;
    public Timer retxTimer;
	
    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage: java McCORD <file_name>");
            System.out.println("       Disseminate the file to the network."); 
            System.exit(1);
        }
        String fileName = args[0];
        new McCORD(fileName);
    }

    public McCORD (String fileName) {
        moteIf = new MoteIF(PrintStreamMessenger.err);
        moteIf.start();

        moteIf.registerListener(new UARTMetaMsg(), this);
        moteIf.registerListener(new UARTDataMsg(), this);

        // Open the file.
        File file = null;
        try {
            file = new File(fileName);
            if (!file.exists() || !file.canRead() || file.length() == 0) {
                System.out.println("File " + fileName + " does not exist, " +
                                   "or cannot read, or is empty!");
                System.exit(1);
            }
            fis = new FileInputStream(file);
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Prepare messages.
        metaMsg = new UARTMetaMsg();
        dataMsg = new UARTDataMsg();

        // Computes number of packets needed. Always round up.
        int packets = (int)((file.length() + Consts.BYTES_PER_PKT - 1) 
                            / Consts.BYTES_PER_PKT);
        int pages = packets / Consts.PKTS_PER_PAGE;
        int packetsLastPage = packets % Consts.PKTS_PER_PAGE;
        if (packetsLastPage == 0) {
            packetsLastPage = Consts.PKTS_PER_PAGE;
        } else {
            pages++;
        }

        metaMsg.set_metadata_objId(1);
        metaMsg.set_metadata_numPages((short)pages);
        metaMsg.set_metadata_numPktsLastPage((short)packetsLastPage);
        metaMsg.set_metadata_numPagesComplete((short)pages);
        metaMsg.set_metadata_pad((short)0);
        metaMsg.set_metadata_crcData((short)0);
        metaMsg.set_metadata_crcMeta(0);
        
        System.out.println("Sending metadata message: " + metaMsg.toString());
        try {
            startTimer(METAMSG_TIMEOUT_MILLIS);
            moteIf.send(MoteIF.TOS_BCAST_ADDR, metaMsg);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
  
    public void messageReceived(int to, Message m) {
        short [] payload = new short[Consts.BYTES_PER_PKT];

        switch (m.amType()) {
            case UARTMetaMsg.AM_TYPE:
                UARTMetaMsg rxMetaMsg = (UARTMetaMsg)m;
                metaAcked = true;
                stopTimer();

                dataMsg.set_page((short)0);
                dataMsg.set_packet((short)0);
                preparePayload(payload);
                dataMsg.set_data(payload);
                System.out.println("Sending Page " + dataMsg.get_page()
                                   + " Packet " + dataMsg.get_packet());
                try {
                    startTimer(DATAMSG_TIMEOUT_MILLIS);
                    moteIf.send(MoteIF.TOS_BCAST_ADDR, dataMsg);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;

            case UARTDataMsg.AM_TYPE:
                UARTDataMsg rxDataMsg = (UARTDataMsg)m;
                stopTimer();
  
                int page = dataMsg.get_page();
                int packet = dataMsg.get_packet();
                if (page == metaMsg.get_metadata_numPages() - 1 &&
                    packet == metaMsg.get_metadata_numPktsLastPage() - 1) {
                    System.out.println("Done.");
                    System.exit(0);
                } else {
                    packet++;
                    if (packet == Consts.PKTS_PER_PAGE) {
                        packet = 0;
                        page++;
                    }
                    dataMsg.set_page((short)page);
                    dataMsg.set_packet((short)packet);
                    preparePayload(payload);
                    dataMsg.set_data(payload); 
                    System.out.println("Sending Page " + dataMsg.get_page()
                                       + " Packet " + dataMsg.get_packet());
                    try {
                        startTimer(DATAMSG_TIMEOUT_MILLIS);
                        moteIf.send(MoteIF.TOS_BCAST_ADDR, dataMsg);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                break;
                
            default: 
                break;
        }
    }

    public void startTimer(long timeout) {
        retxTimer = new Timer();
        retxTimer.schedule(new RetxTimerTask(), timeout);
    }

    public void stopTimer() {
        retxTimer.cancel();
    }
	
    private void preparePayload(short [] payload) {
        for (int i = 0; i < Consts.BYTES_PER_PKT; i++)
             payload[i] = 0;
 
        try {
            for (int i = 0; i < Consts.BYTES_PER_PKT; i++) {
                int x = fis.read();
                if (x == -1) break;
                payload[i] = (short)x;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    public class RetxTimerTask extends TimerTask {
        public void run() {
            try {
                if (!metaAcked) {
                    System.out.println("Re-sending metadata message: " 
                                       + metaMsg.toString());
                    startTimer(METAMSG_TIMEOUT_MILLIS);
                    moteIf.send(MoteIF.TOS_BCAST_ADDR, metaMsg);
                } else {
                    System.out.println("Re-sending Page " + dataMsg.get_page()
                                       + " Packet " + dataMsg.get_packet());
                    startTimer(DATAMSG_TIMEOUT_MILLIS);
                    moteIf.send(MoteIF.TOS_BCAST_ADDR, dataMsg);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        } 
    }

}
