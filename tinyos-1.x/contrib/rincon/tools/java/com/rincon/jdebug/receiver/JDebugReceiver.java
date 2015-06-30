package com.rincon.jdebug.receiver;

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

/**
 * @author David Moss (dmm@rincon.com)
 */

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.rincon.jdebug.messages.JDebugMsg;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class JDebugReceiver implements MessageListener {


	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Communication with the mote */
	private static MoteIF comm = new MoteIF((Messenger) null);

	/** Success/Fail definitions */
	private static final short SUCCESS = 1;
	private static final short FAIL = 0;

	/** The current message being built */
	private String finalString = "";
	
	/** True if the next character should represent some sort of number */
	private boolean numberNext = false;
	
	/** True if the current number we're parsing should be in hex */
	private boolean hex = false;
	
	/**
	 * Constructor
	 *
	 */
	public JDebugReceiver() {
		comm.registerListener(new JDebugMsg(), this);
	}
	
	/**
	 * Add a FileTransferEvents listener
	 * @param listener
	 */
	public void addListener(JDebugEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(JDebugEvents listener) {
		listeners.remove(listener);
	}
	
	
	public void messageReceived(int to, Message m) {
		JDebugMsg dbg = (JDebugMsg) m;
		char[] rawString = dbg.getString_msg().toCharArray();

		for(int i = 0; i < rawString.length; i++) {
			if(rawString[i] == '%') {
				numberNext = true;
				// Get the next character...
				continue;
			}
			
			if(!numberNext) {
				finalString +=  rawString[i];
			} else {
				try {
					if(rawString[i] == 'x') {
						hex = true;
						// Get the next character...
						continue;
					}					
					
					if(rawString[i] == 'l') {
						if(hex) {
							finalString += "0x" + Long.toHexString(dbg.get_dlong()).toUpperCase();
						} else {
							finalString += dbg.get_dlong();
						}
					} else if(rawString[i] == 'i') {
						if(hex) {
							finalString += "0x" + Long.toHexString(dbg.get_dint()).toUpperCase();
						} else {
							finalString += dbg.get_dint();
						}
					} else if(rawString[i] == 's') {
						if(hex) {
							finalString += "0x" + Long.toHexString(dbg.get_dshort()).toUpperCase();
						} else {
							finalString += dbg.get_dshort();
						}
					} else {
						finalString += "<type error: '" + rawString[i] + "' >";
					}
					hex = false;
					numberNext = false;
				} catch (ArrayIndexOutOfBoundsException e) {
					finalString += "<parse error>";
				}
			}
		}
		
		if(dbg.get_newLine() == 1) {
			// No more to write
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((JDebugEvents) it.next()).messageReceived(finalString);
				finalString = "";
			}
		}
	}
}
