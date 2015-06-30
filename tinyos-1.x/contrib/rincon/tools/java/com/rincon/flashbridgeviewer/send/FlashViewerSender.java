package com.rincon.flashbridgeviewer.send;

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

import net.tinyos.message.Message;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

import com.rincon.flashbridgeviewer.ViewerCommands;
import com.rincon.flashbridgeviewer.messages.ViewerMsg;
import com.rincon.transfer.TransferCommands;

public class FlashViewerSender implements FlashViewerCommands {
	
	/** Communication with the mote */
	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private ViewerMsg command = new ViewerMsg();
	
	/**
	 * Send a message
	 * @param dest
	 * @param m
	 */
	private void send(int dest, Message m) {
		try {
			comm.send(dest, m);
		} catch (IOException e) {
			System.err.println("Couldn't contact the mote");
		}
	}
	
	
	public void read(long address, int length, int moteID) {
		command.set_addr(address);
		command.set_len(length);
		command.set_cmd(ViewerCommands.CMD_READ);
		send(moteID, command);
	}

	public void write(long address, short[] buffer, int length, int moteID) {
		command.set_addr(address);
		command.set_len(length);
		command.set_data(buffer);
		command.set_cmd(ViewerCommands.CMD_WRITE);
		send(moteID, command);
		
	}

	public void erase(int sector, int moteID) {
		command.set_addr(sector);
		command.set_cmd(ViewerCommands.CMD_ERASE);
		send(moteID, command);
		
	}

	public void crc(long address, int length, int moteID) {
		command.set_addr(address);
		command.set_len(length);
		command.set_cmd(ViewerCommands.CMD_CRC);
		send(moteID, command);
		
	}

	public void flush(int moteID) {
		command.set_cmd(ViewerCommands.CMD_FLUSH);
		send(moteID, command);
	}
	
	public void ping(int moteID) {
		command.set_cmd(ViewerCommands.CMD_PING);
		send(moteID, command);
	}
}
