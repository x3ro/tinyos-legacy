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
 * Blackbook File Reading Interface
 * @author David Moss - dmm@rincon.com
 */

interface BFileRead {

  /**
   * Open a file for reading
   * @param fileName - name of the file to open
   * @return SUCCESS if the attempt to open for reading proceeds
   */ 
  command result_t open(char *fileName);

  /**
   * @return TRUE if the given parameterized interface has a file open
   */
  command bool isOpen();
  
  /**
   * Close any currently opened file
   */
  command result_t close();

  /**
   * Read a specified amount of data from the open
   * file into the given buffer
   * @param *dataBuffer - the buffer to read data into
   * @param amount - the amount of data to read
   * @return SUCCESS if the command goes through
   */
  command result_t read(void *dataBuffer, uint16_t amount);

  /**
   * Seek a given address to read from in the file.
   *
   * This will point the current internal read pointer
   * to the given address if the address is within
   * bounds of the file.  When BFileRead.read(...) is
   * called, the first byte of the buffer
   * will be the byte at the file address specified here.
   *
   * If the address is outside the bounds of the
   * data in the file, the internal read pointer
   * address will not change.
   * @param fileAddress - the address to seek
   * @return SUCCESS if the read pointer is adjusted,
   *         FAIL if the read pointer didn't change
   */
  command result_t seek(uint32_t fileAddress);

  /**
   * Skip the specified number of bytes in the file
   * @param skipLength - number of bytes to skip
   * @return SUCCESS if the internal read pointer was 
   *      adjusted, FAIL if it wasn't because
   *      the skip length is beyond the bounds of the file.
   */
  command result_t skip(uint16_t skipLength);

  /**
   * Get the remaining bytes available to read from this file.
   * This is the total size of the file minus your current position.
   * @return the number of remaining bytes in this file 
   */
  command uint32_t getRemaining();



  /**
   * A file has been opened
   * @param fileName - name of the opened file
   * @param len - the total data length of the file
   * @param result - SUCCESS if the file was successfully opened
   */
  event void opened(uint32_t amount, result_t result);

  /**
   * Any previously opened file is now closed
   * @param result - SUCCESS if the file was closed properly
   */
  event void closed(result_t result);

  /**
   * File read complete
   * @param *buf - this is the buffer that was initially passed in
   * @param amount - the length of the data read into the buffer
   * @param result - SUCCESS if there were no problems reading the data
   */
  event void readDone(void *dataBuffer, uint16_t amount, result_t result);

}


