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

public interface FlashRunnerInterface {

	/**
	 * Read a block of data from flash
	 * @param address
	 * @param range
	 */
	public void read(long address, long range, int moteID);
	
	/**
	 * Write some bytes to flash
	 * @param address
	 * @param buffer
	 * @param length
	 */
	public void write(long address, short[] buffer, int length, int moteID);
	
	/**
	 * Erase the currently mounted sector in flash
	 *
	 */
	public void erase(int sector, int moteID);
	
	/**
	 * Get the crc
	 * @param id
	 */
	public void crc(long addr, int len, int moteID);
	
	/**
	 * Commit changes to flash 
	 *
	 */
	public void flush(int moteID);
	
	/**
	 * Ping the FlashViewer on a mote
	 * @param moteID
	 */
	public void ping(int moteID);
}
