// $Id: LogData.nc,v 1.1.1.1 2007/11/05 19:09:03 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * Authors:		David Gay
 * Date last modified:  7/15/03
 *
 */

/** 
 * This interface is used to provide efficient, byte level logging to
 * a region of memory/flash/etc (the actual region is specified through
 * some other mechanism, e.g., in ByteEEPROM by providing a parameterised
 * LogData interface). Unlike the WriteData interface, the data written
 * via append is only guaranteed to be present in the region once sync
 * has completed.
 *
 * Note: this interface is purposefully restrictive to allow logging to
 * be as fast as possible. Calls to LogData must not be interspersed
 * with calls to WriteData on the same area of memory/flash/etc
 * (ReadData is fine). WriteData can be called after syncDone returns.
 * This interface is currently used by ByteEEPROM
 * @author David Gay
 */

interface LogData
{
  /** Erase region, reset append pointer to beginning of region
   * @return FAIL if erase request was refused. Otherwise SUCCESS
   *   is returned and <code>eraseDone</code> will be signaled.
   */
  command result_t erase();

  /**
   * Report erase completion.
   * @param success FAIL if erase failed, in which case appends are not allowed.
   * @return Ignored.
   */
  event result_t eraseDone(result_t success);

  /** Append bytes to region (erase must be called first)

   * @return FAIL if appends are not allowed (erase failed or sync has been
   * called). If the result is SUCCESS, <code>appendDone</code> will be signaled.
   */
  command result_t append(uint8_t* data, uint32_t numBytes);

  /**
   * Report append completion.
   * @param data Address of data written
   * @param numBytesWrite Number of bytes written
   * @param success SUCCESS if write was successful, FAIL otherwise
   * @return Ignored.
   */
  event result_t appendDone(uint8_t* data, uint32_t numBytes, result_t success);

  /**
   * Report current append offset.
   * @return the current append offset, or (uint32_t)-1
      if appends are not allowed (after sync or before erase)
   */
  command uint32_t currentOffset();

  /** 
   * Ensure all data written by append is committed to flash.
   * Once sync is called, no more appends are allowed.
   * @return FAIL if sync request is refused. If the result is SUCCESS
   * the <code>syncDone</code> event will be signaled.
   */
  command result_t sync();

  /**
   * Report sync completion.
   * @param success FAIL if sync failed, SUCCESS otherwise.
   * @return Ignored.
   */
  event result_t syncDone(result_t success);
}
