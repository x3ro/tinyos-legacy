// $Id: BlockWrite.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

/*									tab:4
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

includes BlockStorage;

/**
 * Write interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */
interface BlockWrite {

  /**
   * Initiate a write operation within a given volume. On SUCCESS, the
   * <code>writeDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin write.
   * @param buf buffer to write data from.
   * @param len number of bytes to write.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t write(block_addr_t addr, void* buf, block_addr_t len);
  /**
   * Signals the completion of a read operation. However, data is not
   * guaranteed to survive a power-cycle unless a commit operation has
   * been completed.
   *
   * @param addr starting address of write.
   * @param buf buffer that written data was read from.
   * @param len number of bytes rwrite.
   * @param result notification of how the operation went.
   */
  event void writeDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len);

  /**
   * Initiate an erase operation. On SUCCESS, the
   * <code>eraseDone</code> event will signal completion of the
   * operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t erase();
  /**
   * Signals the completion of an erase operation.
   *
   * @param result notification of how the operation went.
   */
  event void eraseDone(storage_result_t result);

  /**
   * Initiate a commit operation and finialize any additional writes
   * to the volume. A verify operation from <code>BlockRead</code> can
   * be done to check if the data has been modified since. A commit
   * operation must be issued to ensure that data is stored in
   * non-volatile storage. On SUCCESS, the <code>commitDone</code>
   * event will signal completion of the operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command result_t commit();
  /**
   * Signals the completion of a commit operation. All written data is
   * flushed to non-volatile storage after this event.
   *
   * @param result notification of how the operation went.
   */
  event void commitDone(storage_result_t result);

}
