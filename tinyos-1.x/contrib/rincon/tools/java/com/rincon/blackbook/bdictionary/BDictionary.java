package com.rincon.blackbook.bdictionary;

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

public class BDictionary implements BDictionaryCommands, MessageListener {

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
	public BDictionary() {
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
	public void addListener(BDictionaryEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(BDictionaryEvents listener) {
		listeners.remove(listener);
	}

	
	public void messageReceived(int to, Message m) {
		BlackbookConnectMsg inMsg = (BlackbookConnectMsg) m;
		
		switch(inMsg.get_cmd()) {

		case Commands.REPLY_BDICTIONARY_OPEN:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).opened((int) inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_CLOSE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).closed(inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_INSERT:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).inserted(inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_RETRIEVE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).retrieved(inMsg.get_data(), (int) inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_REMOVE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).removed(inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_NEXTKEY:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).nextKey((int) inMsg.get_length(), inMsg.get_result() == Commands.SUCCESS);
			}
			break;
			
		case Commands.REPLY_BDICTIONARY_ISDICTIONARY:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((BDictionaryEvents) it.next()).fileIsDictionary(inMsg.get_length() == 1, inMsg.get_result() == Commands.SUCCESS);
			}
			break;
		
		case Commands.ERROR_BDICTIONARY_OPEN:
		case Commands.ERROR_BDICTIONARY_CLOSE:
		case Commands.ERROR_BDICTIONARY_INSERT:
		case Commands.ERROR_BDICTIONARY_RETRIEVE:
		case Commands.ERROR_BDICTIONARY_REMOVE:
		case Commands.ERROR_BDICTIONARY_NEXTKEY:
		case Commands.ERROR_BDICTIONARY_FIRSTKEY:
		case Commands.ERROR_BDICTIONARY_ISDICTIONARY:
			System.err.println("Command immediately failed");
			System.exit(0);
		
		default:
		}
		
	}

	public void open(String fileName, int minimumSize) {
		command.set_cmd(Commands.CMD_BDICTIONARY_OPEN);
		command.set_length(minimumSize);
		command.set_data(Util.filenameToData(fileName));
		send(command);
	}

	public void close() {
		command.set_cmd(Commands.CMD_BDICTIONARY_CLOSE);
		send(command);
	}

	public void insert(long key, short[] value, short valueSize) {
		command.set_cmd(Commands.CMD_BDICTIONARY_INSERT);
		command.set_length(key);
		command.set_data(value);
		command.set_result(valueSize);
		send(command);
	}

	public void retrieve(long key) {
		command.set_cmd(Commands.CMD_BDICTIONARY_RETRIEVE);
		command.set_length(key);
		send(command);
	}

	public void remove(long key) {
		command.set_cmd(Commands.CMD_BDICTIONARY_REMOVE);
		command.set_length(key);
		send(command);
	}

	public void getNextKey(long presentKey) {
		command.set_cmd(Commands.CMD_BDICTIONARY_NEXTKEY);
		command.set_length(presentKey);
		send(command);
	}
	
	public void getFirstKey() {
		command.set_cmd(Commands.CMD_BDICTIONARY_FIRSTKEY);
		send(command);
	}
	
	public void isFileDictionary(String fileName) {
		command.set_cmd(Commands.CMD_BDICTIONARY_ISDICTIONARY);
		command.set_data(Util.filenameToData(fileName));
		send(command);
	}
}
