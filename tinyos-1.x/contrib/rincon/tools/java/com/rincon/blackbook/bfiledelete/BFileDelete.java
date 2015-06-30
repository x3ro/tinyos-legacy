package com.rincon.blackbook.bfiledelete;

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

import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.rincon.blackbook.Commands;
import com.rincon.blackbook.Util;
import com.rincon.blackbook.messages.BlackbookConnectMsg;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class BFileDelete implements BFileDeleteCommands, MessageListener {

	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private BlackbookConnectMsg command = new BlackbookConnectMsg();
	
	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Current destination address */
	private int dest = Commands.TOS_BCAST_ADDR;
	

	/**
	 * Set the destination address of the next send command
	 * @param destination
	 */
	public void setDestination(int destination) {
		dest = destination;
	}
	
	/**
	 * Constructor
	 *
	 */
	public BFileDelete() {
		comm.registerListener(new BlackbookConnectMsg(), this);
	}
	
	/**
	 * Send a message
	 * @param dest
	 * @param m
	 */
	private void send(Message m) {
		try {
			comm.send(dest, m);
		} catch (IOException e) {
			System.err.println("Couldn't contact the mote");
		}
	}

	/**
	 * Add a FileTransferEvents listener
	 * @param listener
	 */
	public void addListener(BFileDeleteEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(BFileDeleteEvents listener) {
		listeners.remove(listener);
	}

	public void messageReceived(int to, Message m) {
		BlackbookConnectMsg inMsg = (BlackbookConnectMsg) m;
		
		
		switch(inMsg.get_cmd()) {
		case Commands.REPLY_BFILEDELETE_DELETE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileDeleteEvents) it.next()).deleted(inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.ERROR_BFILEDELETE_DELETE:
			System.err.println("Command immediately failed");
			System.exit(0);
			
		default:
				
		}
		
	}

	public void delete(String fileName) {
		command.set_cmd(Commands.CMD_BFILEDELETE_DELETE);
		command.set_data(Util.filenameToData(fileName));
		send(command);
	}
	
	

}
