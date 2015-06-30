package com.rincon.blackbook.bfilewrite;

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

public interface BFileWriteCommands {

	/**
	 * Open a file for writing. 
	 * 
	 * The reservedBytes must be specified to ensure enough memory
	 * exists in flash for the operation. This does not necessarily
	 * reflect how many bytes must be written - if less bytes
	 * are actually written, the physical file size is automatically
	 * adjusted to the nearest page boundary when the file is finalized.
	 * For example, to create a log file that will be able to hold a 
	 * maximum of 64000 bytes, specify the reserveBytes to be 64000. 
	 * Then if you only log 32000 bytes and close the file, the 
	 * physical file size on flash will be around 32k on flash 
	 * instead of 64k.
	 * 
	 * If the file does already exist on flash, 
	 * giving a reserveBytes value that is less than the existing
	 * file size will not affect the original file size.This may give you only
	 * a few bytes of free space to write to, but only a maximum of a page
	 * of flash.You can use BFileDir.getDataLength(String fileName) to 
	 * get the length of an existing file. So say you have
	 * a file already written and closed, and you expect
	 * to write 0x1000 more bytes to it:
	 *
	 * call BFileWrite.open("myFile", 
	 * call BFileDir.getDataLength("myFile") + 0x1000);
	 *
	 * @param fileName - name of the file to write to
	 * @param minimumSize The minimum requested amount of total space
	 *to reserve in the file.The physical size on the
	 *flash may be more by one page of flash.
	 */ 
	public void open(String fileName, long minimumSize);

	/**
	 * Close any currently opened write file.
	 */
	public void close();

	/**
	 * Save the current state of the file, guaranteeing the next time
	 * we experience a catastrophic failure, we will at least be able to
	 * recover data from the open write file up to the point
	 * where save was called.
	 *
	 * If data is simply being logged for a long time, use save() 
	 * periodically but probably more infrequently.
	 *
	 * @return SUCCESS if the currently open file will be saved.
	 */
	public void save();

	/**
	 * Append the specified amount of data from a given buffer
	 * to the open write file.
	 *
	 * @param data - the buffer of data to append
	 * @param amount - the amount of data in the buffer to write.
	 * @return SUCCESS if the data will be written, FAIL if there
	 * is no open file to write to.
	 */ 
	public void append(short[] data, int amount);

	/**
	 * Obtain the remaining bytes available to be written in this file
	 * This is the total reserved length minus your current 
	 * write position
	 * @return the remaining length of the file.
	 */
	public long getRemaining();


}
