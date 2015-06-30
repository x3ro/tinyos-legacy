/**
 * Copyright (c) 2006 - George Mason University
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

package net.tinyos.mctorrent;

import net.tinyos.util.*;
import net.tinyos.packet.*;
import net.tinyos.message.*;

import java.io.*;

public class McTorrent implements MessageListener {
	public static final short TOS_UART_ADDR = 0x007e;
	private MoteIF moteIf;
	private AdvThread advThread;
	private McTorrentImage image;
	private int objId;
	
    public static void main(String[] args) {
        if (args.length != 2) {
            System.out.println("Usage: java McTorrent <ihex_file> <obj_id>");
            System.exit(1);
        }
        String ihexFileName = args[0];
        int objId = Integer.parseInt(args[1]);
	if (objId <= 0 || objId > 65535) {
		System.out.println("<obj_id> must be 1-65535.");
		System.exit(1);
	}
        new McTorrent(ihexFileName, objId);
    }

    public McTorrent (String ihexFileName, int objId) {
        try {
			image = new McTorrentImage(ihexFileName);
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(1);
		}
        this.objId = objId;
		moteIf = new MoteIF(PrintStreamMessenger.err);
		moteIf.start();

        moteIf.registerListener(new ReqMsg(), this);
        moteIf.registerListener(new AdvMsg(), this);
        
        advThread = new AdvThread(image, objId, moteIf);
        advThread.start();
    }
  
	public void messageReceived(int to, Message m) {
		switch (m.amType()) {
		case AdvMsg.AM_TYPE:
			AdvMsg advMsg = (AdvMsg)m;
			boolean stop = false;
			if (advMsg.get_objId() > objId 
				|| (advMsg.get_objId() == objId
					&& advMsg.get_crcData() != image.getCrc())) {
				System.out.println("A newer object (ID: " 
					+ advMsg.get_objId()
					+ ") is installed on the mote.");
				System.out.println("Please re-try with a higher object ID.");
				stop = true;
			} else if (advMsg.get_objId() == objId
					&& advMsg.get_numPagesComplete() == advMsg.get_numPages()) {
				stop = true;
			}
			if (stop == true) {
				advThread.setStopped();
				try {
					advThread.join();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				System.exit(0);
			}
			break;
			
		case ReqMsg.AM_TYPE:
			ReqMsg reqMsg = (ReqMsg)m;
			ChnMsg chnMsg = new ChnMsg();
			short pageToSend = reqMsg.get_pageId();
			short [] pktsToSend = reqMsg.get_requestedPkts();
			chnMsg.set_dataChannel((short)0);
			chnMsg.set_moreChnMsg((short)0);
			chnMsg.set_objId((short)objId);
			chnMsg.set_srcAddr(TOS_UART_ADDR);
			chnMsg.set_pageId(pageToSend);
			chnMsg.set_pktsToSend(pktsToSend);
			try {
					moteIf.send(MoteIF.TOS_BCAST_ADDR, chnMsg);
				} catch (IOException e) {
					e.printStackTrace();
					System.exit(1);
				}
			advThread.setActivity();
			sendData(pageToSend, pktsToSend);
			advThread.setActivity();
			break;
		default: 
			break;
		}
	}
	
	private void sendData(short pageToSend, short [] pktsToSend) {
		System.out.print("Sending Page " + pageToSend + ": ");
		DataMsg dataMsg = new DataMsg();
		short [] payload = new short[Consts.BYTES_PER_PKT];
		dataMsg.set_objId((short)objId);
		dataMsg.set_pageId(pageToSend);
		dataMsg.set_srcAddr(TOS_UART_ADDR);
		for (int i = 0; i < Consts.PKTS_PER_PAGE; i++) {
			if ((pktsToSend[i/8]&(1 << (i%8))) != 0) {
				System.out.print(" " + i);
				dataMsg.set_pktId((short)i);				
				preparePayload(payload, pageToSend, (short)i);
				dataMsg.set_data(payload);
				try {
					moteIf.send(MoteIF.TOS_BCAST_ADDR, dataMsg);
					Thread.sleep(10);
				} catch (Exception e) {
					e.printStackTrace();
					System.exit(1);
				}
			}
		}
		System.out.println();
	}
	
	private void preparePayload(short [] payload, short pageId, short pktId) {
		
		int imageOffset = pageId * Consts.BYTES_PER_PAGE + pktId * Consts.BYTES_PER_PKT;
		byte [] imageBytes = image.getBytes();

		for (int i = 0; i < Consts.BYTES_PER_PKT; i++)
			payload[i] = (short)(imageBytes[imageOffset + i] & 0xff);

		return;
	}

    
    public class AdvThread extends Thread {
    	private MoteIF moteIf;
     	private AdvMsg advMsg;
    	private McTorrentImage image;
    	private long lastActivityTime;
    	private boolean stopped;
    	
    	public AdvThread(McTorrentImage image, int objId, MoteIF moteIf) {
    		super();
    		   		
			this.image = image;
			this.moteIf = moteIf;
    		advMsg = new AdvMsg();
    		advMsg.set_dataChannel((short)0);
    		advMsg.set_numPages((short)(image.getNumPages()));
    		advMsg.set_numPagesComplete((short)(image.getNumPages()));
    		advMsg.set_numPktsLastPage((short)(image.getNumPktsLastPage()));
    		advMsg.set_objId((short)objId);
    		advMsg.set_srcAddr(TOS_UART_ADDR);
    		advMsg.set_crcData(image.getCrc());
    		lastActivityTime = 0;
    		stopped = false;
    	}
    	
    	synchronized public void setActivity() {
    		lastActivityTime = System.currentTimeMillis();
    	}
    	
    	public void setStopped() {
    		stopped = true;
    	}
    	
    	public void run() {
    		 while (!stopped) {
    			 if (System.currentTimeMillis() > (lastActivityTime + 5000)) {
    				 try {
						moteIf.send(MoteIF.TOS_BCAST_ADDR, advMsg);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
    				 setActivity(); 
    				 try {
						sleep(1000);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
    			 }
    		 }
    	}
    }

}
