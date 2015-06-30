package com.rincon.blackbook.bdictionary;

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

public interface BDictionaryEvents {

	/**
	 * A Dictionary file was opened successfully.
	 * @param totalSize - the total amount of flash space dedicated to storing
	 * key-value pairs in the file
	 * @param remainingBytes - the remaining amount of space left to write to
	 * @param result - SUCCESS if the file was successfully opened.
	 */
	public void opened(int totalSize, boolean result);
	
	/** 
	 * The opened Dictionary file is now closed
	 * @param result - SUCCSESS if there are no open files
	 */
	public void closed(boolean result);
	
	/**
	 * A key-value pair was inserted into the currently opened Dictionary file.
	 * @param key - the key used to insert the value
	 * @param value - pointer to the buffer containing the value.
	 * @param valueSize - the amount of bytes copied from the buffer into flash
	 * @param result - SUCCESS if the key was written successfully.
	 */
	public void inserted(long key, boolean result);
	
	/**
	 * A value was retrieved from the given key.
	 * @param key - the key used to find the value
	 * @param valueHolder - pointer to the buffer where the value was stored
	 * @param valueSize - the actual size of the value.
	 * @param result - SUCCESS if the value was pulled out and is uncorrupted
	 */
	public void retrieved(short[] valueHolder, int valueSize, boolean result);
	
	/**
	 * A key-value pair was removed
	 * @param key - the key that should no longer exist
	 * @param result - SUCCESS if the key was really removed
	 */
	public void removed(long key, boolean result);
	
	/**
	 * The next key in the open Dictionary file
	 * @param nextKey - the next key
	 * @param result - SUCCESS if this is the really the next key,
	 * FAIL if the presentKey was invalid or there is no next key.
	 */
	public void nextKey(long nextKey, boolean result);
	
	/**
	 * @param isDictionary - true if the file is a dictionary file
	 * @param result - SUCCESS if this result is valid
	 */
	public void fileIsDictionary(boolean isDictionary, boolean result);

}
