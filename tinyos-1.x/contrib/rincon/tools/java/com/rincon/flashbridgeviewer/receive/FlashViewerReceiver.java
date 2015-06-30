package com.rincon.flashbridgeviewer.receive;

/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.rincon.flashbridgeviewer.ViewerCommands;
import com.rincon.flashbridgeviewer.messages.ViewerMsg;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class FlashViewerReceiver implements MessageListener {

	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Communication with the mote */
	private static MoteIF comm = new MoteIF((Messenger) null);


	/**
	 * Constructor
	 *
	 */
	public FlashViewerReceiver() {
		comm.registerListener(new ViewerMsg(), this);
	}
	
	/**
	 * Add a FileTransferEvents listener
	 * @param listener
	 */
	public void addListener(FlashViewerEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(FlashViewerEvents listener) {
		listeners.remove(listener);
	}
	
	
	/**
	 * Received a ViewerMsg from UART
	 */
	public void messageReceived(int to, Message m) {
		ViewerMsg inMsg = (ViewerMsg) m;
		
		switch(inMsg.get_cmd()) {
		case ViewerCommands.REPLY_FLUSH:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).flushDone(true);
			}
			break;
		
		case ViewerCommands.REPLY_FLUSH_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).flushDone(false);
			}
			break;
		
		case ViewerCommands.REPLY_FLUSH_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).flushDone(false);
			}
			break;
			
		case ViewerCommands.REPLY_ERASE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone((int)inMsg.get_addr(), true);
			}
			break;
			
		case ViewerCommands.REPLY_ERASE_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone((int)inMsg.get_addr(), false);
			}
			break;
		
		case ViewerCommands.REPLY_ERASE_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone((int)inMsg.get_addr(), false);
			}
			break;
			
		case ViewerCommands.REPLY_CRC:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).crcDone(inMsg.get_len(), true);
			}
			break;
			
		case ViewerCommands.REPLY_CRC_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).crcDone(inMsg.get_len(), false);
			}
			break;
			
			
		case ViewerCommands.REPLY_CRC_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).crcDone(inMsg.get_len(), false);
			}
			break;
		
		case ViewerCommands.REPLY_READ:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), true);
			}
			break;
			
		case ViewerCommands.REPLY_READ_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_READ_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), true);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_PING:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).pong();
			}
			break;
			
		default:
			System.err.println("Unrecognized FlashViewer message received (cmd " + inMsg.get_cmd() + ")");
			
		}
	}

}
