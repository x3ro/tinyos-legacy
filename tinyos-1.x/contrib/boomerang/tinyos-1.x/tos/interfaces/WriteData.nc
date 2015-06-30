// $Id: WriteData.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

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
 * Authors:		David Gay, Philip Levis, Nelson Lee
 * Date last modified:  8/13/02
 *
 *
 */

/**
 * General interface to write n bytes of data to a particular offset.
 * @author David Gay
 * @author Philip Levis
 * @author Nelson Lee
 */
interface WriteData
{ 
  /**
   * Write data.
   * @param offset Offset at which to write.
   * @param data data to write
   * @param numBytesWrite number of bytes to write
   * @return FAIL if the write request is refused. If the result is SUCCESS, 
   *   the <code>writeDone</code> event will be signaled.
   */
  command result_t write(uint32_t offset, uint8_t *data, uint32_t numBytesWrite);		

  /**
   * Signal write completion
   * @param data Address of data written
   * @param numBytesWrite Number of bytes written
   * @param success SUCCESS if write was successful, FAIL otherwise
   * @return Ignored.
   */
  event result_t writeDone(uint8_t *data, uint32_t numBytesWrite, result_t success);
}
