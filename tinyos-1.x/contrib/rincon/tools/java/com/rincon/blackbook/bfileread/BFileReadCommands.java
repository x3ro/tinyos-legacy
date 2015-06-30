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

public interface BFileReadCommands {

	/**
	 * Open a file for reading
	 * @param fileName - name of the file to open
	 * @return SUCCESS if the attempt to open for reading proceeds
	 */ 
	public void open(String fileName);

	/**
	 * Close any currently opened file
	 */
	public void close();

	/**
	 * Read a specified amount of data from the open
	 * file into the given buffer
	 * @param *dataBuffer - the buffer to read data into
	 * @param amount - the amount of data to read
	 * @return SUCCESS if the public goes through
	 */
	public void read(int amount);

	/**
	 * Seek a given address to read from in the file.
	 *
	 * This will point the current internal read pointer
	 * to the given address if the address is within
	 * bounds of the file.When BFileRead.read(...) is
	 * called, the first byte of the buffer
	 * will be the byte at the file address specified here.
	 *
	 * If the address is outside the bounds of the
	 * data in the file, the internal read pointer
	 * address will not change.
	 * @param fileAddress - the address to seek
	 * @return SUCCESS if the read pointer is adjusted,
	 * FAIL if the read pointer didn't change
	 */
	public void seek(long fileAddress);

	/**
	 * Skip the specified number of bytes in the file
	 * @param skipLength - number of bytes to skip
	 * @return SUCCESS if the internal read pointer was 
	 *adjusted, FAIL if it wasn't because
	 *the skip length is beyond the bounds of the file.
	 */
	public void skip(int skipLength);

	/**
	 * Get the remaining bytes available to read from this file.
	 * This is the total size of the file minus your current position.
	 * @return the number of remaining bytes in this file 
	 */
	public long getRemaining();
	
}
