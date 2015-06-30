// $Id: AllocationReq.nc,v 1.1.1.1 2007/11/05 19:09:01 jpolastre Exp $

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
 * Authors:		Nelson Lee, David Gay
 * Date last modified:  8/13/02
 *
 *
 */

/**
 * This interface is used as a two-phase allocation protocol for
 * ByteEEPROM. Applications that require memory from the flash call request or
 * requestAddr in their <code>StdControl.init</code> command. They later get a
 * <code>requestProcessed</code> event back reporting success or failure of
 * the allocation.
 * @author Nelson Lee
 * @author David Gay
 */

interface AllocationReq
{
  /**
   * Request a <code>numBytesReq</code> byte section of the flash. This request
   * must be made at initilisation time (at the same time as ByteEEPROM is
   * initialised)
   * @param numBytesReq Number of bytes required
   * @return FAIL for invalid arguments, or if the flash has already been
   *   allocated. <code>requestProcessed</code> will be signaled if SUCCESS
   *   is returned.
   */
  command result_t request(uint32_t numBytesReq);

  /**
   * Request a specific section of the flash. This request must be made at
   * initilisation time (at the same time as ByteEEPROM is initialised)
   * @param byteAddr The starting byte offset. This must be on a page boundary
   * (the <code>TOS_BYTEEEPROM_PAGESIZE</code> constant gives the page size)
   * @param numBytesReq Number of bytes required 
   * @return FAIL for invalid arguments, or if the flash has already been
   *   allocated. <code>requestProcessed</code> will be signaled if SUCCESS
   *   is returned.
   */
  command result_t requestAddr(uint32_t byteAddr, uint32_t numBytesReq);

  /**
   * Signal result of a flash allocation request.
   * @param success SUCCESS if the requested flash section was allocated.
   * @return Ignored.
   */
  event result_t requestProcessed(result_t success);
}




