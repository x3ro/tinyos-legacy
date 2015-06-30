package com.rincon.flashbridgeviewer;

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

import com.rincon.flashbridgeviewer.messages.ViewerMsg;
import com.rincon.flashbridgeviewer.receive.FlashViewerEvents;
import com.rincon.flashbridgeviewer.receive.FlashViewerReceiver;
import com.rincon.flashbridgeviewer.send.FlashViewerSender;

public class CommandRunner implements FlashViewerEvents, FlashRunnerInterface {


	/** Receiving Mechanism */
	private FlashViewerReceiver receiver = new FlashViewerReceiver();
	
	/** Sending mechanism */
	private FlashViewerSender mote = new FlashViewerSender();
	
	/** Total range of data to read */
	private long totalRange;
	
	/** Current range of data to read */
	private int focusedRange;
	
	/** Current address to start reading from */
	private long focusedAddress;
	
	/** The address we started reading from */
	private long startAddress;
	
	/** The mote we're communicating with right now */
	private int focusedMote;
	
	/** Method to output data */
	private DataOutput output = new DataOutput();
	
	/**
	 * Constructor
	 *
	 */
	public CommandRunner() {
		receiver.addListener(this);
	}

	/**
	 * Read some arbitrary range of values from the flash
	 */
	public void read(long address, long range, int moteID) {
		totalRange = range;
		startAddress = address;
		focusedAddress = address;
		focusedMote = moteID;
		if(range > ViewerMsg.totalSize_data()) {
			focusedRange = ViewerMsg.totalSize_data();
		} else {
			focusedRange = (int) range;
		}
		
		System.out.println("0x" + Long.toHexString(startAddress) + " to 0x" + Long.toHexString(startAddress + totalRange));
		System.out.println("_________________________________________________");
		
		mote.read(address, focusedRange, focusedMote);
		
	}

	/**
	 * Write data to the flash
	 */
	public void write(long address, short[] buffer, int length, int moteID) {
		mote.write(address, buffer, length, moteID);	
	}

	/**
	 * Erase data from the flash
	 */
	public void erase(int sector, int moteID) {
		mote.erase(sector, moteID);
	}

	/**
	 * Mount to a volume id
	 */
	public void crc(long address, int length, int moteID) {
		mote.crc(address, length, moteID);
	}

	/**
	 * Commit to flash
	 */
	public void flush(int moteID) {
		mote.flush(moteID);
	}

	/**
	 * Ping the FlashViewer component on the mote.
	 */
	public void ping(int moteID) {
		mote.ping(moteID);
	}

	
	/**
	 * Read is complete
	 */
	public void readDone(long address, short[] buffer, int length, boolean success) {
		output.output(buffer, length);
		
		if(!success) {
			System.out.println("Failure to read data at " + Long.toHexString(address));
			System.exit(1);
		}
		
		focusedAddress += length;
		if(focusedAddress < startAddress + totalRange) {
			if(((startAddress + totalRange) - focusedAddress) > ViewerMsg.totalSize_data()) {
				focusedRange = ViewerMsg.totalSize_data();
			} else {
				focusedRange = (int) ((startAddress + totalRange) - focusedAddress);
			}
			mote.read(focusedAddress, focusedRange, focusedMote);
		} else {
			output.flush();
			System.exit(0);
		}
	}

	/**
	 * Write is complete
	 */
	public void writeDone(long address, short[] buffer, int length, boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println(length + " bytes written to 0x" + Long.toHexString(address).toUpperCase());
		System.exit(0);
	}

	/**
	 * Erase is complete
	 */
	public void eraseDone(int sector, boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("Sector " + sector + " erase complete");
		System.exit(0);
	}


	/**
	 * Flush is complete
	 */
	public void flushDone(boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("Flush complete");
		System.exit(0);
		
	}
	
	/**
	 * Ping is complete
	 */
	public void pong() {
		System.out.println("Pong! The mote has FlashViewer installed.");
		System.exit(0);
	}

	public void crcDone(int crc, boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("CRC is 0x" + Integer.toHexString(crc).toUpperCase());
		System.exit(0);
	}

}
