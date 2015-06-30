package com.rincon.blackbook.bfiledir;

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

public interface BFileDirCommands {

	/**
	 * @return the total number of files in the file system
	 */
	public short getTotalFiles();
	
	
	/**
	 * @return the total number of nodes in the file system
	 */
	public int getTotalNodes();

	/**
	 * @return the approximate free space on flash
	 */
	public long getFreeSpace();
	
	/**
	 * Returns TRUE if the file exists, FALSE if it doesn't
	 */
	public void checkExists(String fileName);
	
	/**
	 * An optional way to read the first filename from
	 * the system.  This is the same as calling
	 * BFileDir.readNext(NULL)
	 */
	public void readFirst();
	
	/**
	 * Read the next file in the file system, based on the
	 * current filename.If you want to find the first
	 * file in the file system, pass in NULL.
	 *
	 * If the next file exists, it will be returned in the
	 * nextFile event with result SUCCESS
	 *
	 * If there is no next file, the nextFile event will
	 * signal with the filename passed in and FAIL.
	 *
	 * If the present filename passed in doesn't exist,
	 * then this public returns FAIL and no signal is given.
	 *
	 * @param presentFilename - the name of the current file,
	 * of which you want to find the next valid file after.
	 */
	public void readNext(String presentFilename);

	/**
	 * Get the total reserved bytes of an existing file
	 * @param fileName - the name of the file to pull the reservedLength from.
	 * @return the reservedLength of the file, 0 if it doesn't exist
	 */
	public long getReservedLength(String fileName);
	
	/**
	 * Get the total amount of data written to the file with
	 * the given fileName.
	 * @param fileName - name of the file to pull the dataLength from.
	 * @return the dataLength of the file, 0 if it doesn't exist
	 */
	public long getDataLength(String fileName);
	 
	/**
	 * Find if a file is corrupt. This will read each node
	 * from the file and verify it against its dataCrc.
	 * If the calculated data CRC from a node does
	 * not match the node's recorded CRC, the file is corrupt.
	 * @return SUCCESS if the corrupt check will proceed.
	 */
	public void checkCorruption(String fileName);



}
