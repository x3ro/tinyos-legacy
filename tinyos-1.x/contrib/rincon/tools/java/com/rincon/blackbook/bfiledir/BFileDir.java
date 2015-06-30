package com.rincon.blackbook.bfiledir;

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

public class BFileDir implements BFileDirCommands, MessageListener {

	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private BlackbookConnectMsg command = new BlackbookConnectMsg();
	
	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Current destination address */
	private int dest = Commands.TOS_BCAST_ADDR;
	
	/** Return value for inline commands */
	private long returnAmount = 0;

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
	public BFileDir() {
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
	public void addListener(BFileDirEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(BFileDirEvents listener) {
		listeners.remove(listener);
	}

	public synchronized void messageReceived(int to, Message m) {
		BlackbookConnectMsg inMsg = (BlackbookConnectMsg) m;
		
		switch(inMsg.get_cmd()) {

		case Commands.REPLY_BFILEDIR_TOTALFILES:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		case Commands.REPLY_BFILEDIR_TOTALNODES:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		case Commands.REPLY_BFILEDIR_EXISTS:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileDirEvents) it.next()).existsCheckDone(inMsg.get_length() == 1, inMsg.get_result() == Commands.SUCCESS); 
			}
			break;
			
		case Commands.REPLY_BFILEDIR_READNEXT:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileDirEvents) it.next()).nextFile(Util.dataToFilename(inMsg.get_data()), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BFILEDIR_RESERVEDLENGTH:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		case Commands.REPLY_BFILEDIR_DATALENGTH:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		case Commands.REPLY_BFILEDIR_GETFREESPACE:
			returnAmount = inMsg.get_length();
			notify();
			break;
			
		case Commands.REPLY_BFILEDIR_CHECKCORRUPTION:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BFileDirEvents) it.next()).corruptionCheckDone(inMsg.get_length() == 1, inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
			
		case Commands.ERROR_BFILEDIR_TOTALFILES:
		case Commands.ERROR_BFILEDIR_TOTALNODES:
		case Commands.ERROR_BFILEDIR_EXISTS:
		case Commands.ERROR_BFILEDIR_READNEXT:
		case Commands.ERROR_BFILEDIR_RESERVEDLENGTH:
		case Commands.ERROR_BFILEDIR_DATALENGTH:
		case Commands.ERROR_BFILEDIR_CHECKCORRUPTION:
		case Commands.ERROR_BFILEDIR_READFIRST:
		case Commands.ERROR_BFILEDIR_GETFREESPACE:
			System.err.println("Command immediately failed");
			System.exit(1);
		
		default:
		}
		
	}

	
	
	public synchronized short getTotalFiles() {
		command.set_cmd(Commands.CMD_BFILEDIR_TOTALFILES);
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return (short) returnAmount;
	}

	public synchronized int getTotalNodes() {
		command.set_cmd(Commands.CMD_BFILEDIR_TOTALNODES);
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return (int) returnAmount;
	}
	
	public synchronized long getFreeSpace() {
		command.set_cmd(Commands.CMD_BFILEDIR_GETFREESPACE);
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		return returnAmount;
	}

	public void checkExists(String fileName) {
		command.set_cmd(Commands.CMD_BFILEDIR_EXISTS);
		command.set_data(Util.filenameToData(fileName));
		send(command);
	}

	public void readFirst() {
		command.set_cmd(Commands.CMD_BFILEDIR_READFIRST);
		send(command);
	}
	
	public void readNext(String presentFilename) {
		command.set_cmd(Commands.CMD_BFILEDIR_READNEXT);
		command.set_data(Util.filenameToData(presentFilename));
		send(command);
	}

	public synchronized long getReservedLength(String fileName) {
		command.set_cmd(Commands.CMD_BFILEDIR_RESERVEDLENGTH);
		command.set_data(Util.filenameToData(fileName));
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return returnAmount;
	}

	public synchronized long getDataLength(String fileName) {
		command.set_cmd(Commands.CMD_BFILEDIR_DATALENGTH);
		command.set_data(Util.filenameToData(fileName));
		send(command);
		try {
			wait(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return returnAmount;
	}

	public void checkCorruption(String fileName) {
		command.set_cmd(Commands.CMD_BFILEDIR_CHECKCORRUPTION);
		command.set_data(Util.filenameToData(fileName));
		send(command);
	}
	
}
