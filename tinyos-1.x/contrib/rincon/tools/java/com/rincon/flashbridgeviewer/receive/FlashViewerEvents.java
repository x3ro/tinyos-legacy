package com.rincon.flashbridgeviewer.receive;

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

public interface FlashViewerEvents {

	/**
	 * Read is complete
	 * @param address
	 * @param buffer
	 * @param length
	 * @param success
	 */
	public void readDone(long address, short[] buffer, int length, boolean success);
	
	/**
	 * Write is complete
	 * @param address
	 * @param buffer
	 * @param length
	 * @param success
	 */
	public void writeDone(long address, short[] buffer, int length, boolean success);
	
	/**
	 * Erase is complete
	 * @param success
	 */
	public void eraseDone(int sector, boolean success);
	
	/**
	 * Crc is complete
	 * @param id
	 * @param success
	 */
	public void crcDone(int calculatedCrc, boolean success);
	
	/**
	 * Commit is complete
	 * @param success
	 */
	public void flushDone(boolean success);
	
	/**
	 * Ping received a pong
	 *
	 */
	public void pong();
}
