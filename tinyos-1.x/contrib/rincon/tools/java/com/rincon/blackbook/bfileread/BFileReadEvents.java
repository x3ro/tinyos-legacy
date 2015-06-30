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

public interface BFileReadEvents {


	/**
	 * A file has been opened
	 * @param fileName - name of the opened file
	 * @param len - the total data length of the file
	 * @param result - SUCCESS if the file was successfully opened
	 */
	public void opened(String fileName, long amount, boolean result);

	/**
	 * Any previously opened file is now closed
	 * @param result - SUCCESS if the file was closed properly
	 */
	public void closed(boolean result);

	/**
	 * File read complete
	 * @param *buf - this is the buffer that was initially passed in
	 * @param amount - the length of the data read into the buffer
	 * @param result - SUCCESS if there were no problems reading the data
	 */
	public void readDone(short[] dataBuffer, int amount, boolean result);

}
