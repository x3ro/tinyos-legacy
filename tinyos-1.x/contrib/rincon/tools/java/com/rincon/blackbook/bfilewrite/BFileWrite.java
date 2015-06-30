package com.rincon.blackbook.bfilewrite;

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

public class BFileWrite implements BFileWriteCommands, MessageListener {

	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private BlackbookConnectMsg command = new BlackbookConnectMsg();
	
	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Current destination address */
	private int dest = Commands.TOS_BCAST_ADDR;
	
	/** Return amount for the getRemaining command */
	private long returnAmount;

	/**
	 * Constructor
	 *
	 */
	public BFileWrite() {
		comm.registerListener(new BlackbookConnectMsg(), this);
	}

	/**
	 * Set the destination address of the next send command
	 * @param destination
	 */
	public void setDestination(int destination) {
		dest = destination;
	}
	
	/**
	 * Send a message
	 * @param dest
	 * @param m
	 */
	private synchronized void send(Message m) {
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
	public void addListener(BFileWriteEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remoe a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(BFileWriteEvents listener) {
		listeners.remove(listener);
	}

	public synchronized void messageReceived(int to, Message m) {
		BlackbookConnectMsg inMsg = (BlackbookConnectMsg) m;
		
		switch(inMsg.get_cmd()) {
		case Commands.REPLY_BFILEWRITE_OPEN:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileWriteEvents) it.next()).opened(Util.dataToFilename(inMsg.get_data()), inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEWRITE_CLOSE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileWriteEvents) it.next()).closed(inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEWRITE_SAVE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileWriteEvents) it.next()).saved(inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEWRITE_APPEND:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileWriteEvents) it.next()).appended((int) inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEWRITE_REMAINING:
			returnAmount = inMsg.get_length();
			notify();
			break;
		
		// I know BClean doesn't belong here, but it's good to know why we're waiting
		case Commands.REPLY_BCLEAN_ERASING:
			System.out.println("Erasing...");
			break;
			
		case Commands.ERROR_BFILEWRITE_OPEN:
		case Commands.ERROR_BFILEWRITE_CLOSE:
		case Commands.ERROR_BFILEWRITE_SAVE:
		case Commands.ERROR_BFILEWRITE_APPEND:
		case Commands.ERROR_BFILEWRITE_REMAINING:
			System.err.println("Command immediately failed");
			System.exit(1);
			
		default:
		
		}
		
	}
	
	
	
	public void open(String fileName, long minimumSize) {
		command.set_data(Util.filenameToData(fileName));
		command.set_cmd(Commands.CMD_BFILEWRITE_OPEN);
		command.set_length(minimumSize);
		send(command);
	}

	public void close() {
		command.set_cmd(Commands.CMD_BFILEWRITE_CLOSE);
		send(command);
	}

	public void save() {
		command.set_cmd(Commands.CMD_BFILEWRITE_SAVE);
		send(command);
	}

	public void append(short[] data, int amount) {
		command.set_data(data);
		command.set_length(amount);
		command.set_cmd(Commands.CMD_BFILEWRITE_APPEND);
		send(command);
	}

	public synchronized long getRemaining() {
		command.set_cmd(Commands.CMD_BFILEWRITE_REMAINING);
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return returnAmount;
	}


}
