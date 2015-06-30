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
 * Blackbook NodeMap interface
 * NodeMap controls all nodes in memory, and regulates
 * access to those nodes.  This direct interface
 * only helps control and find information about nodes.
 *
 * @author David Moss (dmm@rincon.com)
 */

includes Blackbook;

interface NodeMap {

  /**
   * @return the maximum number of nodes allowed
   */
  command uint16_t getMaxNodes();
  
  /** 
   * @return the maximum number of files allowed
   */
  command uint8_t getMaxFiles();
  
  /** 
   * @return the total nodes used by the file system
   */
  command uint16_t getTotalNodes();
  
  /**
   * @return the total nodes allocated to the given file
   */
  command uint8_t getTotalNodesInFile(file *focusedFile);
  
  /**
   * @return the total files used by the file system
   */
  command uint8_t getTotalFiles();
  
  /**
   * Get the flashnode and offset into the flashnode that represents
   * an address in a file
   * @param focusedFile - the file to find the address in
   * @param fileAddress - the address to find
   * @param returnOffset - pointer to a location to store the offset into the node
   * @return the flashnode that contains the file address in the file.
   */
  command flashnode *getAddressInFile(file *focusedFile, uint32_t fileAddress, uint16_t *returnOffset); 
  
  /**
   * @return the node's position in a file, 0xFF if not valid
   *
  command uint8_t getElementNumber(flashnode *focusedNode);
  
  /**
   * If you already know the file, this is faster than getElementNumber(..)
   * @return the node's position in the given file, 0xFF if not valid
   *
  command uint8_t getElementNumberFromFile(flashnode *focusedNode, file *focusedFile);
  
  /**
   * @return the file with the given name if it exists, NULL if it doesn't
   */
  command file *getFile(filename *name);
  
  /**
   * @return the file associated with the given node, NULL if n/a.
   */
  command file *getFileFromNode(flashnode *focusedNode);
  
  /**
   * Traverse the files on the file system from
   * 0 up to (max files - 1)
   * If performing a DIR, be sure to hide
   * Checkpoint files on the way out.
   * @return the file at the given index
   */
  command file *getFileAtIndex(uint8_t index);
  
  /**
   * Get a flashnode at a given index
   * @return the flashnode if it exists, NULL if it doesn't.
   */
  command flashnode *getNodeAtIndex(uint8_t index);
  
  /** 
   * @return the length of the file's data
   */
  command uint32_t getDataLength(file *focusedFile);
    
  /**
   * @return the reserve length of all nodes in the file
   */
  command uint32_t getReserveLength(file *focuseFile);
  
  /**
   * @return TRUE if there exists another flashnode belonging
   * to the same file with the same element number
   */
  command bool hasDuplicate(flashnode *focusedNode);
  
}

