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
 * Blackbook Fileio Interface
 * Allows data to be appended to a node, and automatically
 * update the node's dataCrc.  This will not enforce
 * the amount of data written to a node, because the
 * FileWriter is responsible for that level of architecture.
 *
 * @author David Moss - dmm@rincon.com
 */
 
interface Fileio {

  /**
   * Write data to the flashnode belonging to the given file
   * at the given address in the file
   * @param focusedFile - the file to write to
   * @param fileAddress - the address to write to in the file
   * @param *data - the data to write
   * @param amount - the amount of data to write
   * @return SUCCESS if the data will be written
   */
  command result_t writeData(file *focusedFile, uint32_t fileAddress, void *data, uint32_t amount);
  
  /**
   * Read data from the flashnode belonging to the given file
   * at the given address in the file
   * @param focusedFile - the file to read from
   * @param fileAddress - the address to read from in the file
   * @param *data - pointer to the buffer to store the data in
   * @param amount - the amount of data to read
   */
  command result_t readData(file *focusedFile, uint32_t fileAddress, void *data, uint32_t amount);
  
  /**
   * Flush any written data to flash 
   * @return SUCCESS if the data is flushed, and an event will be signaled.
   */
  command result_t flushData();
  
  
  /**
   * Data was appended to the flashnode in the flash.
   * @param writeBuffer - pointer to the buffer containing the data written
   * @param amountWritten - the amount of data appended to the node.
   * @param result - SUCCESS if the data was successfully written
   */
  event void writeDone(void *writeBuffer, uint32_t amountWritten, result_t result);
  
  /**
   * Data was read from the file
   * @param *readBuffer - pointer to the location where the data was stored
   * @param amountRead - the amount of data actually read
   * @param result - SUCCESS if the data was successfully read
   */
  event void readDone(void *readBuffer, uint32_t amountRead, result_t result);
  
  /**
   * Data was flushed to flash
   * @param result - SUCCESS if the data was flushed
   */
  event void flushDone(result_t result);
}


