// $Id: FileRead.nc,v 1.1 2006/10/11 00:11:09 lnachman Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 * Ported to Imote2 by Junaith Ahemed
 */

includes BlockStorage;

interface FileRead 
{
  /**
   * BlockRead.read
   *
   * Read data from the mounted file and store it in buf. It is required
   * that the caller should allocate enough memory for <I>buf</I> to hold
   * data of size <I>len</I>.
   * The starting logical address has to be passed as the first parameter.
   *
   * @param addr Virtual address ranging from 0x0 to SIZE_OF_FILE
   * @param buf Buffer in which the file data will be stored.
   * @param len Number of bytes to be read from the file.
   * 
   * @return SUCCESS | FAIL
   */
  command result_t read(block_addr_t addr, void* buf, block_addr_t len);
  event void readDone(storage_result_t result, block_addr_t addr, 
                      void* buf, block_addr_t len);
  /**
   * BlockRead.fread
   *
   * Read data from the mounted file and store it in buf. It is required
   * that the caller should allocate enough memory for <I>buf</I> to hold
   * data of size <I>len</I>. The read starts from the current read pointer
   * location.
   *
   * @param buf Buffer in which the file data will be stored.
   * @param len Number of bytes to be read from the file.
   *
   * @return SUCCESS | FAIL
   */
  command result_t fread(void* buf, block_addr_t len);

  /**
   * BlockRead.verify
   *
   * NOTE IMPLEMENTED
   * FIXME Should be removed.
   */
  command result_t verify();
  event void verifyDone(storage_result_t result);

  /**
   * BlockRead.computeCrc
   * 
   * Compute CRC of a given section of the file or the whole file based on
   * <I>addr</I> and <I>len</I>.
   * 
   * @return SUCCESS | FAIL
   */
  command result_t computeCrc(block_addr_t addr, block_addr_t len);
  event void computeCrcDone(storage_result_t result, uint16_t crc, 
                            block_addr_t addr, block_addr_t len);

  /**
   * BlockRead.getSize
   * 
   * The function returns the size of the currently mounted file. The
   * function calls getVolumeSize of SectorStorage which calculate
   * the file size based on the number of blocks allocated to the file.
   *
   * @return size The size of the file.
   */  
  command block_addr_t getSize();

  /**
   * BlockRead.getReadPtr
   *
   * Function returns the current read pointer for the mounted
   * file. Note that the read pointer is a ram variable and will
   * be automatically reset when the system restarts.
   *
   * @return readPtr Logical address of the Read Pointer.
   */  
  command block_addr_t getReadPtr ();

  /**
   * BlockRead.resetReadPtr
   *
   * Reset the logical address of the read pointer to 0x0 for the
   * file mounted using blockId.
   *
   * @return SUCCESS | FAIL
   */  
  command result_t resetReadPtr ();

  /**
   * BlockRead.rseek
   *
   * Move the read pointer to a given location within the file. The
   * first parameter should range from 0x0 to Size_of_file.
   *
   * @param addr Virtual address ranging from 0x0 to SIZE_OF_FILE
   * 
   * @return SUCCESS | FAIL
   */  
  command result_t rseek (block_addr_t addr);
}
