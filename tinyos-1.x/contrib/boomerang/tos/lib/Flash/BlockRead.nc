// $Id: BlockRead.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

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

/**
 * Read interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes BlockStorage;

interface BlockRead {

  /**
   * Initiate a read operation within a given volume. On SUCCESS, the
   * <code>readDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin reading.
   * @param buf buffer to place read data.
   * @param len number of bytes to read.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t read(block_addr_t addr, void* buf, block_addr_t len);

  /**
   * Signals the completion of a read operation.
   *
   * @param addr starting address of read.
   * @param buf buffer where read data was placed.
   * @param len number of bytes read.
   * @param result notification of how the operation went.
   */
  event void readDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len);

  /**
   * Initiate a verify operation to verify the integrity of the
   * data. This operation is only valid after a commit operation from
   * <code>BlockWrite</code> has been completed. On SUCCESS, the
   * <code>verifyDone</code> event will signal completion of the
   * operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t verify();
  /**
   * Signals the completion of a verify operation.
   *
   * @param error notification of how the operation went.
   */
  event void verifyDone(storage_result_t result);

  /**
   * Initiate a crc computation. On SUCCESS, the
   * <code>computeCrcDone</code> event will signal completion of the
   * operation.
   *
   * @param addr starting address.
   * @param len the number of bytes to compute the crc over.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t computeCrc(block_addr_t addr, block_addr_t len);
  /**
   * Signals the completion of a crc computation.
   *
   * @param addr stating address.
   * @param len number of bytes the crc was computed over.
   * @param crc the resulting crc value.
   * @param result notification of how the operation went.
   */
  event void computeCrcDone(storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len);

  /**
   * Report volume size in bytes.
   * @return Volume size.
   */
  command block_addr_t getSize();

}
