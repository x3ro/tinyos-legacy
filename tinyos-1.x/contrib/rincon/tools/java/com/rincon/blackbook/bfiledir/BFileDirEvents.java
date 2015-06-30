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

public interface BFileDirEvents {

	/**
	 * The corruption check on a file is complete
	 * @param fileName - the name of the file that was checked
	 * @param isCorrupt - TRUE if the file's actual data does not match its CRC
	 * @param result - SUCCESS if this information is valid.
	 */
	public void corruptionCheckDone(boolean isCorrupt, boolean result);

	/**
	 * The check to see if a file exists is complete
	 * @param fileName - the name of the file
	 * @param doesExist - TRUE if the file exists
	 * @param result - SUCCESS if this information is valid
	 */
	public void existsCheckDone(boolean doesExist, boolean result);
	
	
	/**
	 * This is the next file in the file system after the given
	 * present file.
	 * @param fileName - name of the next file
	 * @param result - SUCCESS if this is actually the next file, 
	 * FAIL if the given present file is not valid or there is no
	 * next file.
	 */
	public void nextFile(String fileName, boolean result);
	
}
