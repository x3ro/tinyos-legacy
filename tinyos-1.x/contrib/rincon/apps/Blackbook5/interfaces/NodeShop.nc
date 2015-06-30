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

/**
 * Blackbook NodeShop interface
 * At the command of the NodeMap, nodes are converted to meta
 * and written to flash.  Nodes can also be deleted from flash.
 *
 * @author David Moss (dmm@rincon.com)
 */
 
includes Blackbook;

interface NodeShop {
  
  /**
   * Write the nodemeta to flash for the given node
   * @param focusedFile - the file to write the nodemeta for
   * @param focusedNode - the flashnode to write the nodemeta for
   * @param name - pointer to the name of the file if this is the first node
   */
  command result_t writeNodemeta(file *focusedFile, flashnode *focusedNode, filename *name);
  
  /**
   * Delete a flashnode on flash. This will not erase the
   * data from flash, but it will simply mark the magic
   * number of the flashnode to make it invalid.
   * 
   * After the command is called and executed, a metaDeleted
   * event will be signaled.
   *
   * @return SUCCESS if the magic number will be marked
   */
  command result_t deleteNode(flashnode *focusedNode);
  
  /**
   * Get the CRC of a flashnode on flash.
   *
   * After the command is called and executed, a crcCalculated
   * event will be signaled.
   *
   * @param focusedNode - the flashnode to read and calculate a CRC for
   * @return SUCCESS if the CRC will be calculated.
   */
  command result_t getCrc(flashnode *focusedNode, file *focusedFile);

  /**
   * Get the filename for a file
   * @param focusedFile - the file to obtain the filename for
   * @param *name - pointer to store the filename
   */
  command result_t getFilename(file *focusedFile, filename *name);
  
  
  
  /** 
   * The node's metadata was written to flash
   * @param focusedNode - the flashnode that metadata was written for
   * @param result - SUCCESS if it was written
   */
  event void metaWritten(flashnode *focusedNode, result_t result);
  
  /**
   * The filename was retrieved from flash
   * @param focusedFile - the file that we obtained the filename for
   * @param *name - pointer to where the filename was stored
   * @param result - SUCCESS if the filename was retrieved
   */
  event void filenameRetrieved(file *focusedFile, filename *name, result_t result);
  
  /**
   * A flashnode was deleted from flash by marking its magic number
   * invalid in the metadata.
   * @param focusedNode - the flashnode that was deleted.
   * @param result - SUCCESS if the flashnode was deleted successfully.
   */
  event void metaDeleted(flashnode *focusedNode, result_t result);
 
  /**
   * A crc was calculated from flashnode data on flash
   * @param dataCrc - the crc of the data read from the flashnode on flash.
   * @param result - SUCCESS if the crc is valid
   */
  event void crcCalculated(uint16_t dataCrc, result_t result);
  
}


