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
 * Blackbook File Write Interface
 */

interface BFileWrite {

  /**
   * Open a file for writing. 
   * @param fileName - name of the file to write to
   * @param minimumSize The minimum requested amount of total data space
   *            to reserve in the file.  The physical amount of flash 
   *            consumed by the file may be more.
   */ 
  command result_t open(char *fileName, uint32_t minimumSize);

  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool isOpen();
  
  /**
   * Close any currently opened write file.
   */
  command result_t close();

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
  command result_t save();

  /**
   * Append the specified amount of data from a given buffer
   * to the open write file.  
   *
   * @param data - the buffer of data to append
   * @param amount - the amount of data in the buffer to write.
   * @return SUCCESS if the data will be written, FAIL if there
   *     is no open file to write to.
   */ 
  command result_t append(void *data, uint16_t amount);

  /**
   * Obtain the remaining bytes available to be written in this file
   * This is the total reserved length minus your current 
   * write position
   * @return the remaining length of the file.
   */
  command uint32_t getRemaining();
  


  /**
   * Signaled when a file has been opened, with the results
   * @param fileName - the name of the opened write file
   * @param len - The total reserved length of the file
   * @param result - SUCCSES if the file was opened successfully
   */
  event void opened(uint32_t len, result_t result);

  /** 
   * Signaled when the opened file has been closed
   * @param result - SUCCESS if the file was closed properly
   */
  event void closed(result_t result);

  /**
   * Signaled when this file has been saved.
   * This does not require the save() command to be called
   * before being signaled - this would happen if another
   * file was open for writing and that file was saved, but
   * the behavior of the checkpoint file required all files
   * on the system to be saved as well.
   * @param fileName - name of the open write file that was saved
   * @param result - SUCCESS if the file was saved successfully
   */
  event void saved(result_t result);

  /**
   * Signaled when data is written to flash. On some media,
   * the data is not guaranteed to be written to non-volatile memory
   * until save() or close() is called.
   * @param fileName
   * @param data The buffer of data appended to flash
   * @param amountWritten The amount written to flash
   * @param result
   */
  event void appended(void *data, uint16_t amountWritten, result_t result);

} 
