package com.rincon.blackbook.bfileread;

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

public class BFileRead implements BFileReadCommands, MessageListener {

	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private BlackbookConnectMsg command = new BlackbookConnectMsg();
	
	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Current destination address */
	private int dest = Commands.TOS_BCAST_ADDR;
	
	/** Amount to return on a getRemaining command */
	private long returnAmount;

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
	public BFileRead() {
		comm.registerListener(new BlackbookConnectMsg(), this);
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
	public void addListener(BFileReadEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(BFileReadEvents listener) {
		listeners.remove(listener);
	}

	
	public synchronized void messageReceived(int to, Message m) {
		BlackbookConnectMsg inMsg = (BlackbookConnectMsg) m;
	
		
		switch(inMsg.get_cmd()) {

		case Commands.REPLY_BFILEREAD_OPEN:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileReadEvents) it.next()).opened(Util.dataToFilename(inMsg.get_data()), inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEREAD_CLOSE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileReadEvents) it.next()).closed(inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEREAD_READ:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileReadEvents) it.next()).readDone(inMsg.get_data(), (int) inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEREAD_SEEK:
			if(inMsg.get_result() == Commands.SUCCESS) {
				System.out.println("Seek success");
			} else {
				System.out.println("Seek failed");
			}
			System.exit(0);
			break;
			
		case Commands.REPLY_BFILEREAD_SKIP:
			if(inMsg.get_result() == Commands.SUCCESS) {
				System.out.println("Skip success");
			} else {
				System.out.println("Skip failed");
			}
			System.exit(0);
			break;
			
		case Commands.REPLY_BFILEREAD_REMAINING:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		
		
		case Commands.ERROR_BFILEREAD_OPEN:
		case Commands.ERROR_BFILEREAD_CLOSE:
		case Commands.ERROR_BFILEREAD_READ:
		case Commands.ERROR_BFILEREAD_SEEK:
		case Commands.ERROR_BFILEREAD_SKIP:
		case Commands.ERROR_BFILEREAD_REMAINING:
			System.err.println("Command immediately failed");
			System.exit(1);
			
		default:
			
		}
		
	}
	
	
	public void open(String fileName) {
		command.set_data(Util.filenameToData(fileName));
		command.set_cmd(Commands.CMD_BFILEREAD_OPEN);
		send(command);
	}
	
	public void close() {
		command.set_cmd(Commands.CMD_BFILEREAD_CLOSE);
		send(command);
	}
	
	public void read(int amount) {
		command.set_cmd(Commands.CMD_BFILEREAD_READ);
		command.set_length(amount);
		send(command);
	}
	
	public void seek(long fileAddress) {
		command.set_cmd(Commands.CMD_BFILEREAD_SEEK);
		command.set_length(fileAddress);
		send(command);
	}
	
	public void skip(int skipLength) {
		command.set_cmd(Commands.CMD_BFILEREAD_SKIP);
		command.set_length(skipLength);
		send(command);
	}
	
	public synchronized long getRemaining() {
		command.set_cmd(Commands.CMD_BFILEREAD_REMAINING);
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
