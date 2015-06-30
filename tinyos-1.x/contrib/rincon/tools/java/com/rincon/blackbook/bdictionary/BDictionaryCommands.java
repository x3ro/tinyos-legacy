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

public interface BDictionaryCommands {

	/**
	 * Open a Dictionary file.If the file does not exist on flash, the
	 * minimumSize will be used to set the length of the file.
	 * @param name - name of the Dictionary file to open
	 * @param minimumSize - the minimum reserved size for the file on flash.
	 * @return SUCCESS if the file will be opened
	 */
	public void open(String fileName, int minimumSize);
	
	/**
	 * Close any opened Dictionary files
	 * @return SUCCESS if the open Dictionary file was closed.
	 */
	public void close();
	
	/**
	 * Insert a key-value pair into the opened Dictionary file.
	 * This will invalidate any old key-value pairs using the
	 * associated key.
	 * @param key - the key to use
	 * @param value - pointer to a buffer containing the value to insert.
	 * @param valueSize - the amount of bytes to copy from the buffer
	 * @return SUCCESS if the key-value pair will be inserted
	 */
	public void insert(long key, short[] value, short valueSize);
	
	/**
	 * Retrieve a key from the opened Dictionary file.
	 * @param key - the key to find
	 * @param valueHolder - pointer to the memory location to store the value
	 * @param maxValueSize - used to prevent buffer overflows incase the
	 * recorded size of the value does not match the space allocated to
	 * the valueHolder
	 * @return SUCCESS if the key will be retrieved.
	 */
	public void retrieve(long key);
	
	/**
	 * Remove a key from the opened dictionary file
	 * @param key - the key for the key-value pair to remove
	 * @return SUCCESS if the attempt to remove the key will proceed
	 */
	public void remove(long key);
	
	
	/**
	 * Get the next recorded key in the file.
	 * @return SUCCESS if the next recorded key will be returned.
	 * FAIL if no keys are defined.
	 */
	public void getNextKey(long presentKey);

	/**
	 * Get the first key of the file
	 *
	 */
	public void getFirstKey();
	
	/**
	 * Find if a file is a dictionary file
	 * 
	 */
	public void isFileDictionary(String fileName);
}
