package com.rincon.flashviewer;

import com.rincon.flashviewer.messages.ViewerMsg;
import com.rincon.flashviewer.receive.FlashViewerEvents;
import com.rincon.flashviewer.receive.FlashViewerReceiver;
import com.rincon.flashviewer.send.FlashViewerSender;

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
	public void erase(int moteID) {
		mote.erase(moteID);
	}

	/**
	 * Mount to a volume id
	 */
	public void mount(short id, int moteID) {
		mote.mount(id, moteID);
	}

	/**
	 * Commit to flash
	 */
	public void commit(int moteID) {
		mote.commit(moteID);
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
	public void eraseDone(boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("Erase complete");
		System.exit(0);
	}

	/**
	 * Mount is complete
	 */
	public void mountDone(int id, boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("Mounted to " + id);
		System.exit(0);
		
	}

	/**
	 * Commit is complete
	 */
	public void commitDone(boolean success) {
		if(success) {
			System.out.print("SUCCESS: ");
		} else {
			System.out.print("FAIL: ");
		}
		
		System.out.println("Commit complete");
		System.exit(0);
		
	}
	
	/**
	 * Ping is complete
	 */
	public void pong() {
		System.out.println("Pong! The mote has FlashViewer installed.");
		System.exit(0);
	}
	
}
