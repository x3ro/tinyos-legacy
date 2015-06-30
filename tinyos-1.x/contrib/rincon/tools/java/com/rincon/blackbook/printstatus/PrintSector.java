package com.rincon.blackbook.printstatus;

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

import com.rincon.blackbook.Commands;
import com.rincon.blackbook.messages.BlackbookSectorMsg;


import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class PrintSector implements MessageListener {

	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private BlackbookSectorMsg outMsg = new BlackbookSectorMsg();
	
	/** Current destination address */
	private int dest = Commands.TOS_BCAST_ADDR;
	
	/**
	 * Constructor
	 *
	 */
	public PrintSector(String[] args) {
		comm.registerListener(new BlackbookSectorMsg(), this);
		if(args.length < 1) {
			System.err.println("PrintSector <sector #>");
			System.exit(1);
		}
		
		outMsg.set_focusedSector_index((short) Integer.parseInt(args[0]));
		send(outMsg);
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
	private void send(Message m) {
		System.out.println("Sent");
		try {
			comm.send(dest, m);
		} catch (IOException e) {
			System.err.println("Couldn't contact the mote");
		}
	}



	public void messageReceived(int to, Message m) {
		BlackbookSectorMsg inMsg = (BlackbookSectorMsg) m;

		System.out.println("\nSector " + outMsg.get_focusedSector_index());
		System.out.println("\ttotalNodes=" + inMsg.get_focusedSector_totalNodes());
		System.out.println("\twritePage=" + inMsg.get_focusedSector_writePage() + " (0x" + Long.toHexString(inMsg.get_focusedSector_writePage()*0x100 + outMsg.get_focusedSector_index() * 0x10000).toUpperCase() + ")");
		System.out.println("\tinUse=" + inMsg.get_focusedSector_inUse());
		
        System.exit(0);
	
	}

	/**
	 * Main Method
	 * @param args
	 */
	public static void main(String[] args) {
		new PrintSector(args);
	}

}
